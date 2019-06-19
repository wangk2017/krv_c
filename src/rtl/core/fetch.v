/*
 Licensed under the Apache License, Version 2.0 (the "License");         
 you may not use this file except in compliance with the License.        
 You may obtain a copy of the License at                                 
                                                                         
     http://www.apache.org/licenses/LICENSE-2.0                          
                                                                         
  Unless required by applicable law or agreed to in writing, software    
 distributed under the License is distributed on an "AS IS" BASIS,       
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and     
 limitations under the License.      
*/

//==============================================================||
// File Name: 		fetch.v					||
// Author:    		Kitty Wang				||
// Description: 						||
//	      		instruction fetch                 	|| 
// History:   							||
//                      2017/9/26 				||
//                      First version				||
//===============================================================



`include "core_defines.vh"

module fetch (
//global signals
input wire cpu_clk,					// cpu clock
input wire cpu_rstn,					// cpu reset, active low
input wire [`ADDR_WIDTH - 1 : 0] boot_addr,		// boot address from SoC

//interface with dec
input wire jal_dec, 					// jal
input wire jalr_ex, 					// jalr
input wire fence_dec,					// fence
output reg [`ADDR_WIDTH - 1 : 0] pc_dec,		// Program counter value for the previous 1 instruction
input wire dec_ready, 					// dec ready signal
output reg if_valid,					// indication of instruction valid
output reg [`INSTR_WIDTH - 1 : 0] instr_dec,		// instruction
input wire signed [`DATA_WIDTH - 1 : 0] src_data1_ex,	// source data 1 at EX stage
input wire signed [`DATA_WIDTH - 1 : 0] imm_ex,		// immediate at ex stage
input wire signed [`DATA_WIDTH - 1 : 0] imm_dec,	// immediate at dec stage
input wire [`ADDR_WIDTH - 1 : 0] pc_ex,			// Program counter value at EX stage

//interface with alu
input wire branch_taken_ex,				// branch condition met

//interface with imem_ctrl
output reg [`ADDR_WIDTH - 1 : 0] next_pc,		// Program counter value for imem addr
input wire instr_read_data_valid,			// instruction valid from imem		
input wire [`INSTR_WIDTH - 1 : 0] instr_read_data, 	// instruction from imem

//interface with trap_ctrl
output reg [`ADDR_WIDTH - 1 : 0] pc,	
input wire mret,					// mret
`ifdef KRV_HAS_DBG
input wire ebreak,
input wire breakpoint,
input wire dbg_mode,					// dbg_mode
input wire dret,					// dret
input wire single_step,					// single_step
input wire single_step_d2,				// single_step delay 1 cycle
input wire [`ADDR_WIDTH - 1 : 0] dpc,			// dpc for return from debug
`endif
output wire pc_misaligned,				// pc misaligned condition found at IF stage
output wire [`ADDR_WIDTH - 1 : 0] fault_pc,		// the misaligned pc recorded at IF stage
input wire trap,					// trap (interrupt or exception) 
input wire  [`ADDR_WIDTH - 1 : 0] vector_addr,		// vector address
input wire [`ADDR_WIDTH - 1 : 0] mepc			// epc for return from trap

);




//--------------------------------------------------------------------------------------//
//add some buffer regs to hold the control state when ITCM disabled
//--------------------------------------------------------------------------------------//
wire if_bubble;
wire [`ADDR_WIDTH - 1 : 0] addr_adder_res;

`ifndef KRV_HAS_ITCM
reg flush_if_r;
reg jal_dec_r;
reg jalr_ex_r;
reg branch_taken_ex_r;
reg [`DATA_WIDTH - 1 : 0] imm_dec_r;
reg mret_r;
reg fence_dec_r;
reg [`ADDR_WIDTH - 1 : 0] addr_adder_res_r;

always @ (posedge cpu_clk or negedge cpu_rstn)
begin
	if (~cpu_rstn)
	begin
		flush_if_r <= 1'b0;
		jal_dec_r <= 1'b0;
		jalr_ex_r <= 1'b0;
		branch_taken_ex_r <= 1'b0;
		mret_r <= 1'b0;
		fence_dec_r <= 1'b0;
		imm_dec_r <= {`DATA_WIDTH{1'b0}};
	end
	else
	begin
	if(instr_read_data_valid)
	begin
		flush_if_r <= 1'b0;
		jal_dec_r <= 1'b0;
		jalr_ex_r <= 1'b0;
		branch_taken_ex_r <= 1'b0;
		mret_r <= 1'b0;
		fence_dec_r <= 1'b0;
		imm_dec_r <= {`DATA_WIDTH{1'b0}};
	end
	else 
	begin
		if(flush_if)
		flush_if_r <= 1'b1;
		if(jal_dec)
		begin
			jal_dec_r <= 1'b1;
			imm_dec_r <= imm_dec;
		end
		if(jalr_ex)
		jalr_ex_r <= 1'b1;
		if(branch_taken_ex)
		branch_taken_ex_r <= 1'b1;
		if(mret)
		mret_r <= 1'b1;
		if(fence_dec)
		fence_dec_r <= 1'b1;
	end
	end
end

reg if_bubble_r;
always @ (posedge cpu_clk or negedge cpu_rstn)
begin
	if (~cpu_rstn)
	begin
		if_bubble_r <= 1'b0;
	end
	else
	begin
		if_bubble_r <= if_bubble;
	end
end

always @ (posedge cpu_clk or negedge cpu_rstn)
begin
	if (~cpu_rstn)
	begin
		addr_adder_res_r <= {`ADDR_WIDTH{1'b0}};
	end
	else 
	begin
		if (instr_read_data_valid)
		begin
			addr_adder_res_r <= {`ADDR_WIDTH{1'b0}};	
		end
		else if(branch_taken_ex || jal_dec || jalr_ex)
		begin
			addr_adder_res_r <= addr_adder_res;
		end
	end

end
wire [`DATA_WIDTH - 1 : 0] imm_dec_f = if_bubble_r ? imm_dec_r : imm_dec;
wire  [`ADDR_WIDTH - 1 : 0] addr_adder_res_c = (branch_taken_ex_r || jal_dec_r || jalr_ex_r )? addr_adder_res_r : addr_adder_res;
`else
wire flush_if_r = 1'b0;
wire jal_dec_r = 1'b0;
wire jalr_ex_r = 1'b0;
wire branch_taken_ex_r = 1'b0;
wire mret_r = 1'b0;
wire fence_dec_r = 1'b0;
wire [`DATA_WIDTH - 1 : 0] imm_dec_f = imm_dec;
wire  [`ADDR_WIDTH - 1 : 0] addr_adder_res_c = addr_adder_res;
`endif

//--------------------------------------------------------------------------------------//
//propagate from IF to DEC stage
//--------------------------------------------------------------------------------------//
`ifdef KRV_HAS_DBG
wire if_stall = dbg_mode && !single_step_d2;
`else
wire if_stall = 1'b0;
`endif

assign if_bubble = !instr_read_data_valid || if_stall;
wire flush_if = fence_dec || fence_dec_r || jal_dec_r || jalr_ex_r || branch_taken_ex || branch_taken_ex_r || trap | mret || mret_r
`ifdef KRV_HAS_DBG
|| ebreak || breakpoint
`endif
;
wire jump = jal_dec || jalr_ex || ((jal_dec_r || jalr_ex_r) && !instr_read_data_valid);

always @ (posedge cpu_clk or negedge cpu_rstn)
begin
	if (~cpu_rstn)
	begin
		instr_dec <= {`INSTR_WIDTH{1'b0}};
		pc_dec <= boot_addr;
		if_valid <= 1'b0;
	end
	else
	begin
		if(flush_if || (flush_if_r && !instr_read_data_valid))
		begin
			instr_dec <= {`INSTR_WIDTH{1'b0}};
			if_valid <= 1'b0;
		end
		else if(dec_ready)
		begin
			if_valid <= 1'b1;
			if(if_bubble || jump)
			begin
				instr_dec <= {`INSTR_WIDTH{1'b0}};
			end
			else
			begin
				instr_dec <= instr_read_data;
				pc_dec <= pc;
			end
		end
	end
end
//--------------------------------------------------------------------------------------//
// PC calculation
//--------------------------------------------------------------------------------------//
//An address adder is used to calculate the next pc based on the conditions listed below
//JAL
//JALR
//Branch
//normal
//--------------------------------------------------------------------------------------//


reg [`ADDR_WIDTH - 1 : 0] addr_adder_src1;
reg [`ADDR_WIDTH - 1 : 0] addr_adder_src2;
assign addr_adder_res = addr_adder_src1 + addr_adder_src2;

always @ *
begin
	if(branch_taken_ex || (branch_taken_ex_r))	//branch taken
	begin
		addr_adder_src1 = pc_ex;
		addr_adder_src2 = imm_ex;
	end
	else if(jalr_ex || (jalr_ex_r))			//jalr
	begin
		addr_adder_src1 = src_data1_ex;
		addr_adder_src2 = imm_ex;
	end
	else if(jal_dec || (jal_dec_r))			//jal
	begin
		addr_adder_src1 = pc_dec;
		addr_adder_src2 = imm_dec_f;
	end
	else						//normal
	begin
		addr_adder_src1 = pc;
		addr_adder_src2 = 4;
	end
end

wire keep_pc = fence_dec || (fence_dec_r && !instr_read_data_valid) || !dec_ready || !instr_read_data_valid;

always @*
begin
`ifdef KRV_HAS_DBG
	if(dret || single_step)
	begin
		next_pc = dpc;
	end
	else if(dbg_mode)		//halt during dbg_mode
	begin
		next_pc = pc;
	end
	else
`endif 
	if(trap)
	begin
		next_pc = vector_addr;
	end
	else if(branch_taken_ex || jalr_ex || jal_dec || ((branch_taken_ex_r || jalr_ex_r || jal_dec_r) && !instr_read_data_valid))
	begin
		next_pc = addr_adder_res_c;
	end
	else if(mret || (mret_r))
	begin
		next_pc = mepc;
	end
	else if (keep_pc)
	begin
		next_pc = pc;
	end
	else
	begin
		next_pc = addr_adder_res_c;
	end
end


always @ (posedge cpu_clk or negedge cpu_rstn)
begin
	if (~cpu_rstn)
	begin
		pc <= boot_addr;
	end
	else
	begin
		pc <= next_pc;
	end
end


//--------------------------------------------------------------------------------------//
// check pc misaligned condition
//--------------------------------------------------------------------------------------//

assign pc_misaligned = (|pc[1:0]);
assign fault_pc = pc_misaligned ? pc : {`ADDR_WIDTH{1'b0}};

//performance counter
wire [31:0] branch_taken_ex_cnt;
en_cnt u_branch_taken_ex_cnt (.clk(cpu_clk), .rstn(cpu_rstn), .en(branch_taken_ex), .cnt (branch_taken_ex_cnt));

wire [31:0] jal_dec_cnt;
en_cnt u_jal_dec_cnt (.clk(cpu_clk), .rstn(cpu_rstn), .en(jal_dec), .cnt (jal_dec_cnt));

wire [31:0] jalr_ex_cnt;
en_cnt u_jalr_ex_cnt (.clk(cpu_clk), .rstn(cpu_rstn), .en(jalr_ex), .cnt (jalr_ex_cnt));


endmodule
