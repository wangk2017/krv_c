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
// File Name: 		dec.v					||
// Author:    		Kitty Wang				||
// Description: 						||
//	      		decoder                           	|| 
// History:   							||
//                      2017/9/26 				||
//                      First version				||
//                      2019/4/16 				||
//                      unify the decoding name 		||
//===============================================================

`include "core_defines.vh"

module dec(
// global signals
input wire cpu_clk,						// cpu clock
input wire cpu_rstn,						// cpu reset, active low

//interface with fetch
input wire if_valid,						// indication of IF stage data valid
output wire dec_ready,						// indication of DEC stage is ready
input wire [`INSTR_WIDTH - 1 : 0] instr_dec,			// instruction at dec stage
input wire [`ADDR_WIDTH - 1 : 0] pc_dec,			// pc propagated from IF stage
output wire fence_dec,						// fence
output reg jalr_ex,						// jalr
output wire jal_dec,						// jal
output reg signed [`DATA_WIDTH - 1 : 0] imm_ex,			// imm at EX stage
output wire signed [`DATA_WIDTH - 1 : 0] imm_dec,		// imm at DEC stage
output wire mret,						// mret

//interface with alu
output reg dec_valid,
input wire ex_ready,
input wire[`DATA_WIDTH - 1 : 0]  alu_result_ex,			// forward result at EX stage
output reg only_src2_used_ex,					// only source data2 will be used at EX stage,
output reg signed [`DATA_WIDTH - 1 : 0]  src_data1_ex,		// source data1 at EX stage
output reg signed [`DATA_WIDTH - 1 : 0]  src_data2_ex,		// source data2 at EX stage
output reg alu_add_ex  ,					// use add at EX stage
output reg alu_sub_ex  ,					// use sub at EX stage			
output reg alu_com_ex  ,					// use compare at EX stage
output reg alu_ucom_ex ,					// use unsigned compare at EX stage
output reg alu_and_ex  ,					// use and at EX stage
output reg alu_or_ex   ,					// use or at EX stage
output reg alu_xor_ex  ,					// use xor at EX stage
output reg alu_sll_ex  ,					// use sll at EX stage
output reg alu_srl_ex  ,					// use srl at EX stage
output reg alu_sra_ex  ,					// use sra at EX stage
output reg alu_mul_ex  ,					// use mul at EX stage
output reg alu_mulh_ex  ,					// use mulh at EX stage
output reg alu_mulhsu_ex  ,					// use mulhsu at EX stage
output reg alu_mulhu_ex  ,					// use mulhu at EX stage
output reg alu_rem_ex  ,					// use rem at EX stage
output reg alu_remu_ex  ,					// use remu at EX stage
output reg alu_div_ex  ,					// use div at EX stage
output reg alu_divu_ex  ,					// use divu at EX stage
output reg beq_ex,						// beq at EX stage
output reg bne_ex,  						// bne at EX stage
output reg blt_ex,  						// blt at EX stage
output reg bge_ex,  						// bge at EX stage
output reg bltu_ex, 						// bltu at EX stage
output reg bgeu_ex, 						// bgeu at EX stage
input wire branch_taken_ex,					// branch condition met at EX stage
output reg load_ex, 						// propagate load to EX stage                   
output reg store_ex, 						// propagate store to EX stage     
output reg [`DATA_WIDTH - 1 : 0] store_data_ex,			// propagate store data to EX stage
output reg mem_H_ex,						// propagate halfword acess to EX stage
output reg mem_B_ex,						// propagate byte accessto EX stage
output reg mem_U_ex,						// propagate unsigned load to EX stage
output reg [`RD_WIDTH:0] rd_ex, 				// propagate rd to EX stage
output reg [`ADDR_WIDTH - 1 : 0] pc_ex,				// propagate pc to EX stage
output reg [`DATA_WIDTH - 1 : 0] instr_ex,			// propagate pc to EX stage

//interface with dmem_ctrl
input wire load_wait_data,
input wire [`RD_WIDTH:0] rd_mem,				// rd at MEM stage	
input wire[`DATA_WIDTH - 1 : 0]  data_mem,			// forward result at MEM stage
input wire mem_wb_data_valid,

//interface with wb_ctrl block
input wire wr_valid_wb,						// gprs write valid at WB stage
input wire[`DATA_WIDTH - 1 : 0]  wr_data_wb,			// gprs write data at WB stage
input wire [`RD_WIDTH:0] rd_wb,					// rd at WB stage


//interface with trap_ctrl
input wire valid_interrupt,					// interrupt 
input wire exception_met,					// exception condition met
output wire load_x0,						// load x0 exception
output wire ecall,						// ecall instruction
output wire ebreak,						// ebreak instruction
output wire instr_illegal,					// illegal instruction exception

//interface with mcsr block
output wire mcsr_rd,						// valid mcsr read signal
output wire mcsr_wr,						// valid mcsr write signal
output wire valid_mcsr_rd,					// valid mcsr read signal
output wire valid_mcsr_wr,					// valid mcsr write signal
output wire mcsr_set,						// valid mcsr set signal
output wire mcsr_clr,						// valid mcsr clear signal
output wire [11:0] mcsr_addr,					// mcsr address
output reg [`DATA_WIDTH - 1 : 0] mcsr_write_data,		// mcsr write data
input wire [`DATA_WIDTH - 1 : 0] mcsr_read_data,		// mcsr read data

//to pg_ctrl
output reg wfi							// WFI

//debug interface
`ifdef KRV_HAS_DBG
,
input				breakpoint,
input [`DATA_WIDTH - 1 : 0] 	d_regs_read_data,
input  				dbg_mode,
input				single_step_d1,
output 				dret,
input				dbg_reg_access,
input 				dbg_wr1_rd0,
input[`CMD_REGNO_SIZE - 1 : 0]	dbg_regno,
input[`DATA_WIDTH - 1 : 0]	dbg_write_data,
output				dbg_read_data_valid,
output[`DATA_WIDTH - 1 : 0]	dbg_read_data
`endif

);



//---------------------------------------------------------------------------//
// instruction decode
//---------------------------------------------------------------------------//

// Obtain each segment from the valid instruction
wire [`INSTR_WIDTH - 1 : 0]     valid_instr;
wire [`FUNCT7_WIDTH - 1 : 0]	funct7;
wire [`FUNCT12_WIDTH - 1 : 0]	funct12;
wire [`RS2_WIDTH - 1 : 0]	rs2;
wire [`RS1_WIDTH - 1 : 0] 	rs1;
wire [`RD_WIDTH - 1  : 0] 	rd;
wire [`FUNCT3_WIDTH - 1 : 0]	funct3;
wire [`OPCODE_WIDTH - 1 : 0]	opcode;

assign valid_instr = (if_valid) ? instr_dec : {`INSTR_WIDTH{1'b0}};

assign opcode 	= valid_instr[`OPCODE_RANGE] ;
assign funct3 	= valid_instr[`FUNCT3_RANGE] ;
assign funct7 	= valid_instr[`FUNCT7_RANGE] ;
assign funct12 	= valid_instr[`FUNCT12_RANGE] ;
assign rs1 	= valid_instr[`RS1_RANGE] ;
assign rs2 	= valid_instr[`RS2_RANGE] ;
assign rd 	= valid_instr[`RD_RANGE] ;

// Decode the instruction type from opcode segment
wire instruction_is_lui;
wire instruction_is_auipc;
wire instruction_is_jal; 
wire instruction_is_jalr; 
wire instruction_is_branch;
wire instruction_is_alu_rr;
wire instruction_is_alu_ir;
wire instruction_is_load;
wire instruction_is_store;
wire instruction_is_system;
wire instruction_is_fence;
wire instruction_is_ecall_brk;

assign instruction_is_lui	 = (opcode==`LUI);
assign instruction_is_auipc	 = (opcode==`AUIPC);
assign instruction_is_jal	 = (opcode==`JAL);
assign instruction_is_jalr	 = (opcode==`JALR);
assign instruction_is_branch	 = (opcode==`BRANCH);
assign instruction_is_load	 = (opcode==`LOAD);
assign instruction_is_store	 = (opcode==`STORE);
assign instruction_is_alu_ir	 = (opcode==`ALU_IR);
assign instruction_is_alu_rr	 = (opcode==`ALU_RR);
assign instruction_is_system	 = (opcode==`SYSTEM);
assign instruction_is_fence	 = (opcode==`FENCE);
assign instruction_is_ecall_brk	 = (opcode==`ECALL_BRK);

wire R_type;
wire I_type;
wire S_type;
wire B_type;
wire J_type;
wire U_type;
assign R_type = instruction_is_alu_rr;
assign I_type = instruction_is_load | instruction_is_alu_ir |
			instruction_is_jalr;
assign S_type = instruction_is_store;
assign B_type = instruction_is_branch;
assign J_type = instruction_is_jal;
assign U_type = instruction_is_lui | instruction_is_auipc;


//funct3 decoding
wire funct3_000;
wire funct3_001;
wire funct3_010;
wire funct3_011;
wire funct3_100;
wire funct3_101;
wire funct3_110;
wire funct3_111;

assign funct3_000 = (funct3 == `FUNCT3_000);
assign funct3_001 = (funct3 == `FUNCT3_001);
assign funct3_010 = (funct3 == `FUNCT3_010);
assign funct3_011 = (funct3 == `FUNCT3_011);
assign funct3_100 = (funct3 == `FUNCT3_100);
assign funct3_101 = (funct3 == `FUNCT3_101);
assign funct3_110 = (funct3 == `FUNCT3_110);
assign funct3_111 = (funct3 == `FUNCT3_111);



//funct12 decoding 
wire funct12_mret;
wire funct12_wfi;
wire funct12_ecall;
wire funct12_ebreak;

assign funct12_mret 	= 	(funct12 == `FUNCT12_MRET);
assign funct12_wfi	= 	(funct12 == `FUNCT12_WFI);
assign funct12_ecall	= 	(funct12 == `FUNCT12_ECALL);
assign funct12_ebreak	= 	(funct12 == `FUNCT12_EBREAK);

//funct7 decoding
wire funct7_000_0000;
wire funct7_000_0001;
wire funct7_010_0000;

assign funct7_000_0000 = (funct7 == `FUNCT7_000_0000);
assign funct7_000_0001 = (funct7 == `FUNCT7_000_0001);
assign funct7_010_0000 = (funct7 == `FUNCT7_010_0000);

//Generate ALU operation signals
wire alu_add_dec;
wire alu_sub_dec;
wire alu_com_dec;
wire alu_ucom_dec;
wire alu_and_dec;
wire alu_or_dec;
wire alu_xor_dec;
wire alu_sll_dec;
wire alu_srl_dec;
wire alu_sra_dec;
wire alu_mul_dec;
wire alu_mulh_dec;
wire alu_mulhsu_dec;
wire alu_mulhu_dec;
wire alu_div_dec;
wire alu_divu_dec;
wire alu_rem_dec;
wire alu_remu_dec;

assign alu_add_dec = instruction_is_auipc || instruction_is_load || instruction_is_store ||
		   ((instruction_is_alu_ir || (instruction_is_alu_rr && funct7_000_0000)) && funct3_000 );

assign alu_sub_dec = (((instruction_is_alu_rr ) &&
		   funct3_000 && funct7_010_0000)) || (instruction_is_branch && (funct3_000 || funct3_001));

assign alu_com_dec = (instruction_is_branch && (funct3_100 || funct3_101 )) ||
		   ((instruction_is_alu_ir || (instruction_is_alu_rr && funct7_000_0000)) && funct3_010);

assign alu_ucom_dec = (instruction_is_branch && (funct3_110 || funct3_111)) ||
		   ((instruction_is_alu_ir || (instruction_is_alu_rr && funct7_000_0000)) &&
		    funct3_011);

assign alu_and_dec = (instruction_is_alu_ir || (instruction_is_alu_rr && funct7_000_0000))&&   funct3_111;

assign alu_or_dec  = (instruction_is_alu_ir || (instruction_is_alu_rr && funct7_000_0000)) &&
		   funct3_110;

assign alu_xor_dec = (instruction_is_alu_ir || (instruction_is_alu_rr && funct7_000_0000)) &&
		   funct3_100;

assign alu_sll_dec = (instruction_is_alu_ir || (instruction_is_alu_rr && funct7_000_0000)) &&
		   funct3_001;

assign alu_srl_dec = (instruction_is_alu_ir || instruction_is_alu_rr) &&
		   funct3_101 && funct7_000_0000;

assign alu_sra_dec = (instruction_is_alu_ir || instruction_is_alu_rr) &&
		   funct3_101 && funct7_010_0000;

`ifdef KRV_SUPPORT_RV32M
assign alu_mul_dec = instruction_is_alu_rr &&
		   funct3_000 && funct7_000_0001;

assign alu_mulh_dec = instruction_is_alu_rr &&
		   funct3_001 && funct7_000_0001;

assign alu_mulhsu_dec = instruction_is_alu_rr &&
		   funct3_010 && funct7_000_0001;

assign alu_mulhu_dec = instruction_is_alu_rr &&
		   funct3_011 && funct7_000_0001;

assign alu_div_dec = instruction_is_alu_rr &&
		   funct3_100 && funct7_000_0001;

assign alu_divu_dec = instruction_is_alu_rr &&
		   funct3_101 && funct7_000_0001;

assign alu_rem_dec = instruction_is_alu_rr &&
		   funct3_110 && funct7_000_0001;

assign alu_remu_dec = instruction_is_alu_rr &&
		   funct3_111 && funct7_000_0001;
`else
assign alu_mul_dec = 1'b0;
assign alu_mulh_dec = 1'b0;
assign alu_mulhsu_dec = 1'b0;
assign alu_mulhu_dec = 1'b0;
assign alu_div_dec = 1'b0;
assign alu_divu_dec = 1'b0;
assign alu_rem_dec = 1'b0;
assign alu_remu_dec = 1'b0;
`endif

//---------------------------------------------------------------------------//
// Obtain source data 
//---------------------------------------------------------------------------//

//register file
wire[`DATA_WIDTH - 1 : 0]  gprs_data1;
wire[`DATA_WIDTH - 1 : 0]  gprs_data2;

gprs u_gprs(
.cpu_clk		(cpu_clk),		//cpu clock
.cpu_rstn		(cpu_rstn),		//cpu reset, active low
//1xwrite point
.wr_valid		(wr_valid_wb),		//write valid
.wr_data		(wr_data_wb), 		//write data
.rd_wb			(rd_wb[4:0]),		//destination index in WB stage

//2xread point
.rs1_dec		(rs1),			//source 1 index 
.rs2_dec		(rs2),			//source 2 index 
.gprs_data1		(gprs_data1),		//source 1 data from gprs
.gprs_data2		(gprs_data2)		//source 2 data from gprs

`ifdef KRV_HAS_DBG
,
.dbg_reg_access		(dbg_reg_access	),
.dbg_wr1_rd0		(dbg_wr1_rd0	),
.dbg_regno		(dbg_regno	),
.dbg_write_data		(dbg_write_data	),
.dbg_read_data_valid	(dbg_read_data_valid),
.dbg_read_data		(dbg_read_data	)
`endif


);

//imm generation block
imm_gen imm_gen_inst (
.instr 		(valid_instr),
.imm_is_I_type 	(I_type),
.imm_is_S_type 	(S_type),
.imm_is_B_type 	(B_type),
.imm_is_J_type 	(J_type),
.imm_is_U_type 	(U_type),
.imm		(imm_dec)
);


//alu source data selection
//FIX when timing from dmem forwarding can't met, can move
//data_mem to the last mux
wire alu_use_rs2;
wire alu_use_imm;

assign alu_use_rs2 = R_type || B_type ;
assign alu_use_imm = I_type || S_type || U_type;

reg signed [`DATA_WIDTH - 1 : 0]  src_data1_dec;	//alu source data1 
reg signed [`DATA_WIDTH - 1 : 0]  src_data2_dec;	//alu source data2 


//extend the rs1/rs2/rd a bit more to avoid reset value match for selection mistake 
wire [`RS1_WIDTH  : 0] 	rs1_dec;
wire [`RS2_WIDTH  : 0]	rs2_dec;
assign rs1_dec = {1'b0,rs1};
assign rs2_dec = {1'b0,rs2};

wire dec_stall;
assign jal_dec = instruction_is_jal && !dec_stall;
wire jalr_dec = instruction_is_jalr && !dec_stall;

wire only_src2_used_dec = instruction_is_lui || mcsr_rd || instruction_is_jal || instruction_is_jalr;  
wire src1_not_used_dec = instruction_is_lui || instruction_is_jal;		   

reg pre_instr_is_load;
reg pre_instr_is_load_r;

always @ *
begin
	if(instruction_is_auipc)
	begin
		src_data1_dec = pc_dec ;
	end
	else
	begin
	  if(!src1_not_used_dec)
		begin
			if(rs1_dec == 0)
			begin
				src_data1_dec = 0;
			end
			else if((!(pre_instr_is_load || pre_instr_is_load_r)) &(rs1_dec == rd_ex))
			begin
				src_data1_dec = alu_result_ex;
			end
			else if (rs1_dec == rd_mem) 
			begin
				src_data1_dec = data_mem;
			end
			else if (rs1_dec == rd_wb)
			begin
				src_data1_dec = wr_data_wb;
			end
			else
			begin
				src_data1_dec = gprs_data1;
			end
		end
	  else //src1_not_used_dec
		begin
			src_data1_dec = 0;
		end
	end
end

reg [`DATA_WIDTH - 1 : 0]  gprs_data2_mux;	 

always @ *
	begin
		if(rs2_dec == 0)
		begin
			gprs_data2_mux = 0;
		end
		else if(!(pre_instr_is_load || pre_instr_is_load_r) && (rs2_dec == rd_ex))
		begin
			gprs_data2_mux = alu_result_ex;
		end
		else if (rs2_dec == rd_mem)
		begin
			gprs_data2_mux = data_mem;
		end
		else if (rs2_dec == rd_wb)
		begin
			gprs_data2_mux = wr_data_wb;
		end
		else
		begin
			gprs_data2_mux = gprs_data2;
		end
	end


always @ *
begin
	if(instruction_is_jal || instruction_is_jalr)
	begin
		src_data2_dec = pc_dec + 4;
	end
	else if(mcsr_rd)
	begin
		src_data2_dec = (mcsr_read_data
`ifdef KRV_HAS_DBG
 | d_regs_read_data
`endif
);
	end
	else if (alu_use_rs2)
	begin
		src_data2_dec = gprs_data2_mux;
	end
	else if(alu_use_imm)
	begin
		src_data2_dec = imm_dec;
	end
	else
	begin
		src_data2_dec = 32'h0;
	end
end

//---------------------------------------------------------------------------//
//3: propagate from DEC to EX stage
//---------------------------------------------------------------------------//
wire dec_bubble = !if_valid || dec_stall;
//dec flush condition
wire flush_dec = branch_taken_ex || jalr_ex || exception_met
`ifdef KRV_HAS_DBG
|| breakpoint
`endif
;

always @ (posedge cpu_clk or negedge cpu_rstn)
begin
	if (!cpu_rstn)
	begin
		dec_valid    <= 1'b0;
	end
	else
	begin
		if (flush_dec)
		begin
			dec_valid    <= 1'b0;
		end
		else if(ex_ready)
		begin
			dec_valid <= 1'b1;
		end
	end
end

always @ (posedge cpu_clk or negedge cpu_rstn)
begin
	if (!cpu_rstn)
	begin
		src_data1_ex <= {`DATA_WIDTH{1'b0}}; 
		src_data2_ex <= {`DATA_WIDTH{1'b0}}; 
		alu_add_ex <= 1'b0;
		alu_sub_ex <= 1'b0;
		alu_com_ex <= 1'b0;
		alu_ucom_ex <= 1'b0;
		alu_and_ex <= 1'b0;
		alu_or_ex <= 1'b0;
		alu_xor_ex <= 1'b0;
		alu_sll_ex <= 1'b0;
		alu_srl_ex <= 1'b0;
		alu_sra_ex <= 1'b0;
		alu_mul_ex <= 1'b0;
		alu_mulh_ex <= 1'b0;
		alu_mulhsu_ex <= 1'b0;
		alu_mulhu_ex <= 1'b0;
		alu_div_ex <= 1'b0;
		alu_divu_ex <= 1'b0;
		alu_rem_ex <= 1'b0;
		alu_remu_ex <= 1'b0;
	end
	else
	begin
		if (flush_dec)
		begin
			alu_add_ex <= 1'b0;
			alu_sub_ex <= 1'b0;
			alu_com_ex <= 1'b0;
			alu_ucom_ex <= 1'b0;
			alu_and_ex <= 1'b0;
			alu_or_ex <= 1'b0;
			alu_xor_ex <= 1'b0;
			alu_sll_ex <= 1'b0;
			alu_srl_ex <= 1'b0;
			alu_sra_ex <= 1'b0;
			alu_mul_ex <= 1'b0;
			alu_mulh_ex <= 1'b0;
			alu_mulhsu_ex <= 1'b0;
			alu_mulhu_ex <= 1'b0;
			alu_div_ex <= 1'b0;
			alu_divu_ex <= 1'b0;
			alu_rem_ex <= 1'b0;
			alu_remu_ex <= 1'b0;
		end
		else if(ex_ready)
		begin
			if(dec_bubble)
			begin
				src_data1_ex <= {`DATA_WIDTH{1'b0}}; 
				src_data2_ex <= {`DATA_WIDTH{1'b0}}; 
				alu_add_ex <= 1'b0;
				alu_sub_ex <= 1'b0;
				alu_com_ex <= 1'b0;
				alu_ucom_ex <= 1'b0;
				alu_and_ex <= 1'b0;
				alu_or_ex <= 1'b0;
				alu_xor_ex <= 1'b0;
				alu_sll_ex <= 1'b0;
				alu_srl_ex <= 1'b0;
				alu_sra_ex <= 1'b0;
				alu_mul_ex <= 1'b0;
				alu_mulh_ex <= 1'b0;
				alu_mulhsu_ex <= 1'b0;
				alu_mulhu_ex <= 1'b0;
				alu_div_ex <= 1'b0;
				alu_divu_ex <= 1'b0;
				alu_rem_ex <= 1'b0;
				alu_remu_ex <= 1'b0;
			end
			else
			begin
				src_data1_ex <= src_data1_dec; 
				src_data2_ex <= src_data2_dec; 
				alu_add_ex <= alu_add_dec;
				alu_sub_ex <= alu_sub_dec;
				alu_com_ex <= alu_com_dec;
				alu_ucom_ex<= alu_ucom_dec;
				alu_and_ex <= alu_and_dec;
				alu_or_ex  <= alu_or_dec;
				alu_xor_ex <= alu_xor_dec;
				alu_sll_ex <= alu_sll_dec;
				alu_srl_ex <= alu_srl_dec;
				alu_sra_ex <= alu_sra_dec;
				alu_mul_ex <= alu_mul_dec;
				alu_mulh_ex <= alu_mulh_dec;
				alu_mulhsu_ex <= alu_mulhsu_dec;
				alu_mulhu_ex <= alu_mulhu_dec;
				alu_div_ex <= alu_div_dec;
				alu_divu_ex<= alu_divu_dec;
				alu_rem_ex <= alu_rem_dec;
				alu_remu_ex <= alu_remu_dec;
			end
		end
	end
end

//for branch 
always @ (posedge cpu_clk or negedge cpu_rstn)
begin
	if (!cpu_rstn)
	begin
		beq_ex <= 1'b0;
		bne_ex <= 1'b0;
		blt_ex <= 1'b0;
		bge_ex <= 1'b0;
		bltu_ex <= 1'b0;
		bgeu_ex <= 1'b0;
	end
	else
	begin
		//if (flush_dec)
		if (jalr_ex || exception_met)
			begin
				beq_ex <= 1'b0;
				bne_ex <= 1'b0;
				blt_ex <= 1'b0;
				bge_ex <= 1'b0;
				bltu_ex <= 1'b0;
				bgeu_ex <= 1'b0;
			end
			else if(ex_ready)
			begin
				if(dec_bubble)
				begin
					beq_ex <= 1'b0;
					bne_ex <= 1'b0;
					blt_ex <= 1'b0;
					bge_ex <= 1'b0;
					bltu_ex <= 1'b0;
					bgeu_ex <= 1'b0;
				end
				else
				begin
					beq_ex <= instruction_is_branch && funct3_000;
					bne_ex <= instruction_is_branch && funct3_001;
					blt_ex <= instruction_is_branch && funct3_100;
					bge_ex <= instruction_is_branch && funct3_101;
					bltu_ex <=instruction_is_branch && funct3_110;
					bgeu_ex <=instruction_is_branch && funct3_111;
				end
			end
	end

end

//for rd
wire use_rd;
assign use_rd = R_type || I_type || U_type || J_type || mcsr_rd;

always @ (posedge cpu_clk or negedge cpu_rstn)
begin
	if(!cpu_rstn)
	begin
		rd_ex <= 32;
	end
	else
	begin
		if(flush_dec)
		begin
			rd_ex <= 32;
		end
		else if(ex_ready)
		begin
			if(dec_bubble || !use_rd)
				rd_ex <= 32;
			else
				rd_ex <= {1'b0,rd};
		end
	end
end

// for load/store
always @ (posedge cpu_clk or negedge cpu_rstn)
begin
	if(!cpu_rstn)
	begin
		store_ex <= 1'b0;
		load_ex <= 1'b0;
		mem_H_ex <= 1'b0;
		mem_B_ex <= 1'b0;
		mem_U_ex <= 1'b0;
		pc_ex <= 0;
		instr_ex <= 0;
		imm_ex <= {`DATA_WIDTH{1'b0}};
		pre_instr_is_load <= 1'b0;
	end
	else
	begin
		if (flush_dec)
		begin
			store_ex <= 1'b0;
			load_ex <= 1'b0;
			pre_instr_is_load <= 1'b0;
			mem_H_ex <= 1'b0;
			mem_B_ex <= 1'b0;
			mem_U_ex <= 1'b0;
		end
		else if(ex_ready)
		begin
			if(dec_bubble)
			begin
				store_ex <= 1'b0;
				load_ex <= 1'b0;
				pre_instr_is_load <= 1'b0;
				mem_H_ex <= 1'b0;
				mem_B_ex <= 1'b0;
				mem_U_ex <= 1'b0;
				pc_ex <= pc_ex;
				instr_ex <= instr_ex;
			end
			else
			begin
				store_ex <= instruction_is_store;
				load_ex <= instruction_is_load;
				pre_instr_is_load <= instruction_is_load;
				mem_H_ex <= (instruction_is_load || instruction_is_store) && (funct3_001 || funct3_101); 
				mem_B_ex <= (instruction_is_load || instruction_is_store) && (funct3_000 || funct3_100); 
				mem_U_ex <= (instruction_is_load || instruction_is_store) && (funct3_101 || funct3_100); 
				pc_ex <= pc_dec;
				instr_ex <= instr_dec;
				imm_ex <= imm_dec;
			end
		end
	end
end

always@(posedge cpu_clk or negedge cpu_rstn)
begin
if(!cpu_rstn)
	begin
		store_data_ex<= {`DATA_WIDTH{1'b0}};
		only_src2_used_ex <= 1'b0;
	end
	else
	begin
		if (flush_dec)
		begin
			store_data_ex<= 0;
			only_src2_used_ex <= 1'b0;
		end
		else if(ex_ready)
		begin
			if(dec_bubble)
			begin
				store_data_ex<= 0;
				only_src2_used_ex <= 1'b0;
			end
			else
			begin
				store_data_ex<= gprs_data2_mux;
				only_src2_used_ex <= only_src2_used_dec || instruction_is_jalr;
			end
		end
	end
end

always@(posedge cpu_clk or negedge cpu_rstn)
begin
if(!cpu_rstn)
	begin
		jalr_ex <= 1'b0;
	end
	else 
	begin
		if(exception_met || branch_taken_ex)
		begin
			jalr_ex <= 1'b0;
		end
		else if(ex_ready)
		begin
			if(dec_bubble)
			begin
				jalr_ex <= 1'b0;
			end
			else
			begin
				jalr_ex <= jalr_dec;
			end
		end
	end
end

//---------------------------------------------------------------------------//
//4: miscellaneous
//---------------------------------------------------------------------------//

//return instruction for trap
assign mret = (instruction_is_system && funct12_mret && funct3_000) && !branch_taken_ex;

//return from debug
`ifdef KRV_HAS_DBG
assign dret = (valid_instr == `DRET) && dbg_mode;
wire illegal_dret = (valid_instr == `DRET) && !dbg_mode;
`else 
wire illegal_dret = 1'b0;

`endif
assign instr_illegal = illegal_dret;

//ecall
assign  ecall = (instruction_is_ecall_brk && funct3_000 && funct12_ecall)
`ifdef KRV_HAS_DBG
&& !dbg_mode
`endif
;

//ebreak
assign  ebreak = instruction_is_ecall_brk && funct3_000 && funct12_ebreak;

//WFI instruction for pg_ctrl
reg wfi_delay1;
reg wfi_delay2;
reg wfi_stall_delay;

wire wfi_i;
assign wfi_i =  ((instruction_is_system && funct12_wfi && funct3_000) && !branch_taken_ex)
`ifdef KRV_HAS_DBG
&& !dbg_mode
`endif
;
//wait for the previous instruction completed
always @ (posedge cpu_clk or negedge cpu_rstn)
begin
	if(!cpu_rstn)
	begin
		wfi_delay1 <= 1'b0;
		wfi_delay2 <= 1'b0;
		wfi <= 1'b0;
		wfi_stall_delay <= 1'b0;
	end
	else
	begin
		if(ex_ready)
		begin
			wfi_delay1 <= wfi_i;
			wfi_delay2 <= wfi_delay1;
			wfi <= wfi_delay2;
			wfi_stall_delay <= wfi;
		end
	end
end


//for mcsr
assign mcsr_addr = valid_instr [31:20];
assign mcsr_rd = instruction_is_system && (((funct3_001 || funct3_101)&&(rd!=0)) || funct3_010 || funct3_011 || funct3_110 || funct3_111 );
assign mcsr_wr = instruction_is_system && (funct3_001 || funct3_101 || ((funct3_010 || funct3_011 || funct3_110 || funct3_111) && (rs1!=0)));
assign valid_mcsr_rd = (!flush_dec) && (ex_ready) && !dec_bubble && mcsr_rd;
assign valid_mcsr_wr = (!flush_dec) && (ex_ready) && !dec_bubble && mcsr_wr;
always @ *
begin
	if (funct3_001 || funct3_010 || funct3_011)
	begin
 		mcsr_write_data =src_data1_dec;
	end
	else if(funct3_101 || funct3_110 || funct3_111)
	begin
		mcsr_write_data = {27'h0, rs1};
	end
	else
	begin
		mcsr_write_data = 32'h0;
	end
end

assign mcsr_set = funct3_010 || funct3_110;
assign mcsr_clr = funct3_011 || funct3_111;

//load X0 exception check
assign load_x0 = instruction_is_load && (!(|rd));

//stall check
//1: previous instruction is load and current instruction use the rd of previous instr as rs
//2: WFI
//3: FENCE

wire load_hazard_1st; //the current instruction uses the load result one previous
wire load_hazard_2nd; //the current instruction uses the load result two previous

wire rs1_wait_load_1st = ((!src1_not_used_dec) && (rs1_dec == rd_ex)) && load_ex;
wire rs2_wait_load_1st = (rs2_dec == rd_ex) && load_ex;

wire rs1_wait_load_2nd = ((!src1_not_used_dec) && (rs1_dec == rd_mem)) && load_wait_data;
wire rs2_wait_load_2nd = (rs2_dec == rd_mem) && load_wait_data;

reg load_hazard_1st_r;
reg load_hazard_2nd_r;

wire [5:0] hazard_rd_1st =  (rs1_wait_load_1st ? rs1_dec : (rs2_wait_load_1st ? rs2_dec : 6'h32));
wire [5:0] hazard_rd_2nd =  (rs1_wait_load_2nd ? rs1_dec : (rs2_wait_load_2nd ? rs2_dec : 6'h32));

wire [5:0] hazard_rd = load_hazard_2nd ? hazard_rd_2nd : hazard_rd_1st;

reg [5:0] hazard_rd_1st_r;
reg [5:0] hazard_rd_2nd_r;

wire load_hazard_1st_clr = mem_wb_data_valid && (rd_mem == hazard_rd_1st_r);
wire load_hazard_2nd_clr = mem_wb_data_valid && (rd_mem == hazard_rd_2nd_r);

assign load_hazard_1st =(((rs1_wait_load_1st || rs2_wait_load_1st )) ) && (!mret) && !load_hazard_1st_r && !load_hazard_1st_clr;
assign load_hazard_2nd =(((rs1_wait_load_2nd || rs2_wait_load_2nd )) ) && (!mret) && !load_hazard_2nd_r && !load_hazard_1st_r && !load_hazard_2nd_clr && !load_hazard_1st_clr;



wire load_hazard_stall_1st = (load_hazard_1st || load_hazard_1st_r) && (!load_hazard_1st_clr);
wire load_hazard_stall_2nd = (load_hazard_2nd || load_hazard_2nd_r) && (!load_hazard_2nd_clr);

wire load_hazard_stall;
assign load_hazard_stall = load_hazard_stall_1st || load_hazard_stall_2nd;  


always@(posedge cpu_clk or negedge cpu_rstn)
begin
	if(!cpu_rstn)
	begin
		load_hazard_1st_r <= 1'b0;
		hazard_rd_1st_r <= 6'h32;
	end
	else if(load_hazard_1st_clr)
	begin
		load_hazard_1st_r <= 1'b0;
		hazard_rd_1st_r <= 6'h32;
	end
	else if(load_hazard_1st)
	begin
		load_hazard_1st_r <= 1'b1;
		hazard_rd_1st_r <= hazard_rd_1st;
	end
end

always@(posedge cpu_clk or negedge cpu_rstn)
begin
	if(!cpu_rstn)
	begin
		load_hazard_2nd_r <= 1'b0;
		hazard_rd_2nd_r <= 6'h32;
	end
	else if(load_hazard_2nd_clr)
	begin
		load_hazard_2nd_r <= 1'b0;
		hazard_rd_2nd_r <= 6'h32;
	end
	else if(load_hazard_2nd)
	begin
		load_hazard_2nd_r <= 1'b1;
		hazard_rd_2nd_r <= hazard_rd_2nd;
	end
end


always@(posedge cpu_clk or negedge cpu_rstn)
begin
	if(!cpu_rstn)
	begin
		pre_instr_is_load_r <= 1'b0;
	end
	else if(load_hazard_1st_clr)
	begin
		pre_instr_is_load_r <= 1'b0;
	end
	else if(load_hazard_1st && pre_instr_is_load)
	begin
		pre_instr_is_load_r <= 1'b1;
	end
end

wire wfi_stall;
assign wfi_stall = wfi_i && !valid_interrupt;

wire fence_stall;
assign fence_dec = (instruction_is_fence && (funct3_000 || funct3_001)) && !fence_stall && !fence_d2 && !fence_d3;
reg fence_d1;
reg fence_d2;
reg fence_d3;
always@(posedge cpu_clk or negedge cpu_rstn)
begin
	if(!cpu_rstn)
	begin
		fence_d1 <= 1'b0;
		fence_d2 <= 1'b0;
		fence_d3 <= 1'b0;
	end
	else
	begin
		fence_d1 <= fence_dec;
		fence_d2 <= fence_d1;
		fence_d3 <= fence_d2;
	end
end
assign fence_stall = fence_d1;

//stall condition met in DEC stage
assign dec_stall = wfi_stall || load_hazard_stall || fence_stall
`ifdef KRV_HAS_DBG
|| (dbg_mode && !single_step_d1)
`endif
;
assign dec_ready = !dec_stall && (ex_ready);

//performance counter
wire [31:0] wfi_stall_cnt;
en_cnt u_wfi_stall_cnt (.clk(cpu_clk), .rstn(cpu_rstn), .en(wfi_stall), .cnt (wfi_stall_cnt));

wire [31:0] load_hazard_stall_cnt;
en_cnt u_load_hazard_stall_cnt (.clk(cpu_clk), .rstn(cpu_rstn), .en(load_hazard_stall), .cnt (load_hazard_stall_cnt));

wire [31:0] fence_stall_cnt;
en_cnt u_fence_stall_cnt (.clk(cpu_clk), .rstn(cpu_rstn), .en(fence_stall), .cnt (fence_stall_cnt));

endmodule

