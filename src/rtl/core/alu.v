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
// File Name: 		alu.v					||
// Author:    		Kitty Wang				||
// Description: 						||
//	      		arithmetic and logic unit         	|| 
// History:   							||
//                      2017/9/26 				||
//                      First version				||
//===============================================================

`include "core_defines.vh"
module alu (
//global signals
input wire cpu_clk,					// cpu clock
input wire cpu_rstn,					// cpu reset, active low


//interface with dec
input wire dec_valid,
output wire ex_ready,
input wire signed [`DATA_WIDTH - 1 : 0] src_data1_ex,	// source data 1 at EX stage
input wire signed [`DATA_WIDTH - 1 : 0] src_data2_ex,	// source data 2 at EX stage
input wire only_src2_used_ex,				// for lui
input wire alu_add_ex,					// add operation at EX stage
input wire alu_sub_ex,					// sub operation at EX stage
input wire alu_com_ex,					// com operation at EX stage
input wire alu_ucom_ex,					// unsigned com operation at EX stage
input wire alu_and_ex,					// and operation at EX stage
input wire alu_or_ex,					// or operation at EX stage
input wire alu_xor_ex,					// xor operation at EX stage
input wire alu_sll_ex,					// sll operation at EX stage
input wire alu_srl_ex,					// srl operation at EX stage
input wire alu_sra_ex,					// sra operation at EX stage
input wire alu_mul_ex,					// mul operation at EX stage
input wire alu_mulh_ex,					// mulh operation at EX stage
input wire alu_mulhsu_ex,				// mulhsu operation at EX stage
input wire alu_mulhu_ex,				// mulhu operation at EX stage
input wire alu_rem_ex,					// rem operation at EX stage
input wire alu_remu_ex,					// remu operation at EX stage
input wire alu_div_ex,					// div operation at EX stage
input wire alu_divu_ex,					// divu operation at EX stage
output wire [`DATA_WIDTH - 1 : 0] alu_result_ex,	// forwarding result at EX stage to DEC stage

input wire beq_ex,					// branch when rs1=rs2
input wire bne_ex,					// branch when rs1!=rs2
input wire blt_ex,					// branch when rs1<rs2
input wire bge_ex,					// branch when rs1>=rs2
input wire bltu_ex,					// branch when rs1<rs2, both treated as unsigned
input wire bgeu_ex,					// branch when rs1>=rs2,both treated as unsigned
output wire branch_taken_ex,				// branch condition met

input wire load_ex, 	  				// load instruction
input wire store_ex, 	    				// store instruction
input wire mem_H_ex,					// memory access halfword
input wire mem_B_ex,					// memory access byte
input wire mem_U_ex,					// load unsigned halfword/byte
input wire [`DATA_WIDTH - 1 : 0] store_data_ex, 	// store source data

input wire [`RD_WIDTH : 0] rd_ex,			// rd at EX stage

//interface with dmem_ctrl 
output reg ex_valid,					// alu result valid at MEM stage
input wire mem_ready,					// ready at MEM stage
output reg [`DATA_WIDTH - 1 : 0] alu_result_mem,	// alu result at MEM stage
output reg [`RD_WIDTH:0] rd_mem,			// rd at MEM stage
output reg load_mem, 					// load at MEM stage  
output reg store_mem,         				// store at MEM stage                        
output reg mem_H_mem,					// halfword access at MEM stage
output reg mem_B_mem,					// byte access at MEM stage
output reg mem_U_mem,					// unsigned load halfword/byte at MEM stage
output reg [`DATA_WIDTH - 1 : 0] store_data_mem,	// store data at MEM stage
output wire [`ADDR_WIDTH - 1 : 0] mem_addr_mem		// memory address at MEM stage
`ifdef KRV_HAS_DBG
,
input wire breakpoint,
input wire dbg_mode,
input wire single_step_d2,
input wire single_step_d3,
input wire single_step_d4,
output wire [`ADDR_WIDTH - 1 : 0] mem_addr_ex		// memory address at MEM stage
`endif


);



//--------------------------------------------------------------------------------//
//ALU operations
//--------------------------------------------------------------------------------//

//1: 32b Adder
wire signed [`DATA_WIDTH - 1 : 0] adder_src_data1;	//source data 1 for adder
wire signed [`DATA_WIDTH - 1 : 0] adder_src_data2;	//source data 2 for adder
wire signed [`DATA_WIDTH - 1 : 0] adder_result;		//result of adder
//gated the source operand when adder not used 
assign adder_src_data1 = (alu_add_ex | alu_sub_ex )? src_data1_ex : {`DATA_WIDTH {1'b0}};
assign adder_src_data2 = alu_add_ex ? src_data2_ex : (alu_sub_ex ? (~src_data2_ex + 32'h1) : {`DATA_WIDTH {1'b0}});
assign adder_result = adder_src_data1 + adder_src_data2;


//2: 32b comparator for rs1 is little than rs2 
wire signed [`DATA_WIDTH - 1 : 0] com_src_data1;	//source data 1 for com
wire signed [`DATA_WIDTH - 1 : 0] com_src_data2;	//source data 2 for com
wire signed [`DATA_WIDTH - 1 : 0] com_result;		//result of com
//gated the source operand when comparator not used 
assign com_src_data1 = alu_com_ex ? src_data1_ex : {`DATA_WIDTH {1'b0}};
assign com_src_data2 = alu_com_ex ? src_data2_ex : {`DATA_WIDTH {1'b0}};
assign com_result = (com_src_data1 < com_src_data2);

//3: 32b unsigned comparator for rs1 is little than rs2  
wire [`DATA_WIDTH - 1 : 0] ucom_src_data1;		//source data 1 for ucom
wire [`DATA_WIDTH - 1 : 0] ucom_src_data2;		//source data 2 for ucom
wire [`DATA_WIDTH - 1 : 0] ucom_result;			//result of ucom
//gated the source operand when comparator not used 
assign ucom_src_data1 = alu_ucom_ex ? src_data1_ex : {`DATA_WIDTH {1'b0}};
assign ucom_src_data2 = alu_ucom_ex ? src_data2_ex : {`DATA_WIDTH {1'b0}};
assign ucom_result = (ucom_src_data1 < ucom_src_data2);

//4: and
wire signed [`DATA_WIDTH - 1 : 0] and_result;		//result of and
assign and_result = alu_and_ex ? src_data1_ex & src_data2_ex : {`DATA_WIDTH{1'b0}};

//5: or
wire signed [`DATA_WIDTH - 1 : 0] or_result;		//result of or
assign or_result = alu_or_ex ? src_data1_ex | src_data2_ex : {`DATA_WIDTH{1'b0}};

//6: xor
wire signed [`DATA_WIDTH - 1 : 0] xor_result;		//result of and
assign xor_result = alu_xor_ex ? src_data1_ex ^ src_data2_ex : {`DATA_WIDTH{1'b0}};



//7: shift left logically
//shift amount For shift operation
wire [`SHAMT_WIDTH - 1 : 0] shamt;
assign shamt = src_data2_ex[`SHAMT_WIDTH - 1 : 0];

wire signed [`DATA_WIDTH - 1 : 0] sll_result;		//result of sll
assign sll_result = alu_sll_ex ? src_data1_ex << shamt : {`DATA_WIDTH{1'b0}};

//8: shift right logically
wire signed [`DATA_WIDTH - 1 : 0] srl_result;		//result of srl
assign srl_result = alu_srl_ex ? src_data1_ex >> shamt : {`DATA_WIDTH{1'b0}};

//9: shift right arithmetically
reg signed [`DATA_WIDTH - 1 : 0] sra_result;		//result of sra
/*
assign sra_result = alu_sra_ex ?  ($signed(src_data1_ex)) >>> shamt : {`DATA_WIDTH{1'b0}};
*/
//FIXME seems >>> has no difference from >>, temporarily use case to solve the issue

always @*
begin
	if(alu_sra_ex)
	begin
		case(shamt)
		5'd0: sra_result = {src_data1_ex};
		5'd1: sra_result = {src_data1_ex[31],src_data1_ex[31:1]};
		5'd2: sra_result = {{2{src_data1_ex[31]}},src_data1_ex[31:2]};
		5'd3: sra_result = {{3{src_data1_ex[31]}},src_data1_ex[31:3]};
		5'd4: sra_result = {{4{src_data1_ex[31]}},src_data1_ex[31:4]};
		5'd5: sra_result = {{5{src_data1_ex[31]}},src_data1_ex[31:5]};
		5'd6: sra_result = {{6{src_data1_ex[31]}},src_data1_ex[31:6]};
		5'd7: sra_result = {{7{src_data1_ex[31]}},src_data1_ex[31:7]};
		5'd8: sra_result = {{8{src_data1_ex[31]}},src_data1_ex[31:8]};
		5'd9: sra_result = {{9{src_data1_ex[31]}},src_data1_ex[31:9]};
		5'd10: sra_result = {{10{src_data1_ex[31]}},src_data1_ex[31:10]};
		5'd11: sra_result = {{11{src_data1_ex[31]}},src_data1_ex[31:11]};
		5'd12: sra_result = {{12{src_data1_ex[31]}},src_data1_ex[31:12]};
		5'd13: sra_result = {{13{src_data1_ex[31]}},src_data1_ex[31:13]};
		5'd14: sra_result = {{14{src_data1_ex[31]}},src_data1_ex[31:14]};
		5'd15: sra_result = {{15{src_data1_ex[31]}},src_data1_ex[31:15]};
		5'd16: sra_result = {{16{src_data1_ex[31]}},src_data1_ex[31:16]};
		5'd17: sra_result = {{17{src_data1_ex[31]}},src_data1_ex[31:17]};
		5'd18: sra_result = {{18{src_data1_ex[31]}},src_data1_ex[31:18]};
		5'd19: sra_result = {{19{src_data1_ex[31]}},src_data1_ex[31:19]};
		5'd20: sra_result = {{20{src_data1_ex[31]}},src_data1_ex[31:20]};
		5'd21: sra_result = {{21{src_data1_ex[31]}},src_data1_ex[31:21]};
		5'd22: sra_result = {{22{src_data1_ex[31]}},src_data1_ex[31:22]};
		5'd23: sra_result = {{23{src_data1_ex[31]}},src_data1_ex[31:23]};
		5'd24: sra_result = {{24{src_data1_ex[31]}},src_data1_ex[31:24]};
		5'd25: sra_result = {{25{src_data1_ex[31]}},src_data1_ex[31:25]};
		5'd26: sra_result = {{26{src_data1_ex[31]}},src_data1_ex[31:26]};
		5'd27: sra_result = {{27{src_data1_ex[31]}},src_data1_ex[31:27]};
		5'd28: sra_result = {{28{src_data1_ex[31]}},src_data1_ex[31:28]};
		5'd29: sra_result = {{29{src_data1_ex[31]}},src_data1_ex[31:29]};
		5'd30: sra_result = {{30{src_data1_ex[31]}},src_data1_ex[31:30]};
		5'd31: sra_result = {{31{src_data1_ex[31]}},src_data1_ex[31:31]};
		endcase
	end
	else
	begin
		sra_result = {`DATA_WIDTH{1'b0}};
	end
end

//10: mul
`ifdef KRV_SUPPORT_RV32M
parameter D_DATA_WIDTH = 2*`DATA_WIDTH;
wire alu_use_mulh = alu_mulh_ex | alu_mulhsu_ex | alu_mulhu_ex;

wire mul_data1_u = alu_mulhu_ex;
wire mul_data2_u = alu_mulhu_ex | alu_mulhsu_ex;
wire mul_data1_s = alu_mul_ex | alu_mulh_ex | alu_mulhsu_ex;
wire mul_data2_s = alu_mul_ex | alu_mulh_ex;

wire [`DATA_WIDTH - 1 : 0] mul_src_data1_s = mul_data1_s ? (src_data1_ex[31] ? ~(src_data1_ex - 32'h1) : src_data1_ex) : {`DATA_WIDTH {1'b0}};	//signed source data 1 for mul
wire [`DATA_WIDTH - 1 : 0] mul_src_data2_s = mul_data2_s ? (src_data2_ex[31] ? ~(src_data2_ex - 32'h1) : src_data2_ex) : {`DATA_WIDTH {1'b0}};	//signed source data 2 for mul

wire [`DATA_WIDTH - 1 : 0] mul_src_data1_u = mul_data1_u ? src_data1_ex : {`DATA_WIDTH {1'b0}};	//unsigned source data 1 for mul
wire [`DATA_WIDTH - 1 : 0] mul_src_data2_u = mul_data2_u ? src_data2_ex : {`DATA_WIDTH {1'b0}};	//unsigned source data 2 for mul

wire [`DATA_WIDTH - 1 : 0] mul_src_data1 = mul_data1_u ? mul_src_data1_u : mul_src_data1_s;	//source data 1 for mul
wire [`DATA_WIDTH - 1 : 0] mul_src_data2 = mul_data2_u ? mul_src_data2_u : mul_src_data2_s;	//source data 2 for mul

wire [`DATA_WIDTH - 1 : 0] mul_result_h;	
wire [`DATA_WIDTH - 1 : 0] mul_result_l;	
assign {mul_result_h,mul_result_l} = (mul_src_data1) * (mul_src_data2);


wire [`DATA_WIDTH - 1 : 0] mul_result_h_s_i;	
wire [`DATA_WIDTH - 1 : 0] mul_result_l_s_i;	
assign {mul_result_h_s_i,mul_result_l_s_i} =  ((|src_data1_ex) & (|src_data2_ex) & (src_data1_ex[31] ^ src_data2_ex[31])) ? (~({mul_result_h,mul_result_l}) + 32'h1) : {mul_result_h,mul_result_l};

wire [`DATA_WIDTH - 1 : 0] mul_result_h_s = alu_mulh_ex ? mul_result_h_s_i : {D_DATA_WIDTH {1'b0}};	
wire [`DATA_WIDTH - 1 : 0] mul_result_l_s = alu_mul_ex ? mul_result_l_s_i : {D_DATA_WIDTH {1'b0}};	

wire [`DATA_WIDTH - 1 : 0] mul_result_h_u;	
wire [`DATA_WIDTH - 1 : 0] mul_result_l_u;	
assign {mul_result_h_u,mul_result_l_u} = alu_mulhu_ex ? {mul_result_h,mul_result_l} : {D_DATA_WIDTH {1'b0}};


wire signed[`DATA_WIDTH - 1 : 0] mul_result_h_su;	
wire signed[`DATA_WIDTH - 1 : 0] mul_result_l_su;	
assign {mul_result_h_su,mul_result_l_su} = alu_mulhsu_ex ?  (((|src_data1_ex) & (|src_data2_ex) & (src_data1_ex[31])) ? (~({mul_result_h,mul_result_l}) + 32'h1) : {mul_result_h,mul_result_l}): {D_DATA_WIDTH {1'b0}};



//11: divider
wire alu_use_div_u = alu_divu_ex | alu_remu_ex;

wire [`DATA_WIDTH - 1 : 0] div_src_data1_u;	//source data 1 for div unsigned
wire [`DATA_WIDTH - 1 : 0] div_src_data2_u;	//source data 2 for div unsigned
assign div_src_data1_u = alu_use_div_u ? src_data1_ex : {`DATA_WIDTH {1'b0}};
assign div_src_data2_u = alu_use_div_u ? src_data2_ex : 32'h1; 

wire alu_use_div_s = alu_div_ex | alu_rem_ex ;
wire [`DATA_WIDTH - 1 : 0] div_src_data1_s;	//source data 1 for div signed
wire [`DATA_WIDTH - 1 : 0] div_src_data2_s;	//source data 2 for div signed
assign div_src_data1_s = alu_use_div_s ? (src_data1_ex[31] ? ~(src_data1_ex - 32'h1) : src_data1_ex) : {`DATA_WIDTH {1'b0}};
assign div_src_data2_s = alu_use_div_s ? (src_data2_ex[31] ? ~(src_data2_ex - 32'h1) : src_data2_ex) : 32'h1; 

wire [`DATA_WIDTH - 1 : 0] div_src_data1;	//source data 1 for div
wire [`DATA_WIDTH - 1 : 0] div_src_data2;	//source data 2 for div
assign div_src_data1 = alu_use_div_u ? div_src_data1_u : div_src_data1_s;
assign div_src_data2 = alu_use_div_u ? div_src_data2_u : div_src_data2_s;

wire [`DATA_WIDTH - 1 : 0] div_result;		//result of div
wire [`DATA_WIDTH - 1 : 0] rem_result;		//result of rem

wire div_start = alu_use_div_u | alu_use_div_s;
wire div_done;

div_u u_div_u (
.cpu_clk	(cpu_clk),
.cpu_rstn	(cpu_rstn),
.start		(div_start),
.done		(div_done),
.div_src_data1	(div_src_data1),	
.div_src_data2	(div_src_data2),	
.rem_result	(rem_result),
.div_result	(div_result)
);

wire [`DATA_WIDTH - 1 : 0] div_result_s_i =  ((|src_data2_ex) && (src_data1_ex[31] ^ src_data2_ex[31])) ? (~div_result + 32'h1) : div_result;
wire [`DATA_WIDTH - 1 : 0] div_result_s = alu_div_ex ? div_result_s_i : {`DATA_WIDTH {1'b0}};		

wire [`DATA_WIDTH - 1 : 0] div_result_u_i =  div_result;
wire [`DATA_WIDTH - 1 : 0] div_result_u = alu_divu_ex ? div_result_u_i : {`DATA_WIDTH {1'b0}};		

wire [`DATA_WIDTH - 1 : 0] rem_result_s_i = src_data1_ex[31] ? (~rem_result + 32'h1) : rem_result;
wire [`DATA_WIDTH - 1 : 0] rem_result_s = (alu_rem_ex) ? rem_result_s_i : {`DATA_WIDTH {1'b0}};		//result of rem

wire [`DATA_WIDTH - 1 : 0] rem_result_u_i = rem_result;
wire [`DATA_WIDTH - 1 : 0] rem_result_u = (alu_remu_ex) ? rem_result_u_i : {`DATA_WIDTH {1'b0}};		//result of rem

`else
wire [`DATA_WIDTH - 1 : 0] mul_result_h_s = {`DATA_WIDTH {1'b0}};
wire [`DATA_WIDTH - 1 : 0] mul_result_l_s = {`DATA_WIDTH {1'b0}};
wire [`DATA_WIDTH - 1 : 0] mul_result_h_u = {`DATA_WIDTH {1'b0}};
wire [`DATA_WIDTH - 1 : 0] mul_result_h_su = {`DATA_WIDTH {1'b0}};
wire [`DATA_WIDTH - 1 : 0] div_result_s = {`DATA_WIDTH {1'b0}};
wire [`DATA_WIDTH - 1 : 0] div_result_u = {`DATA_WIDTH {1'b0}};
wire [`DATA_WIDTH - 1 : 0] rem_result_s = {`DATA_WIDTH {1'b0}};
wire [`DATA_WIDTH - 1 : 0] rem_result_u = {`DATA_WIDTH {1'b0}};
wire div_start = 1'b0;
wire div_done = 1'b0;
`endif //KRV_SUPPORT_RV32M

//alu result
wire signed [`DATA_WIDTH - 1 : 0] alu_result;

assign alu_result = adder_result | com_result | ucom_result | and_result | or_result |
xor_result | sll_result | srl_result | sra_result | mul_result_h_s | mul_result_l_s | mul_result_h_u |  mul_result_h_su |  div_result_u |rem_result_u | div_result_s | rem_result_s; 

//bypass the alu when the instruction is jump or lui
assign alu_result_ex = (only_src2_used_ex ? src_data2_ex : alu_result);

//--------------------------------------------------------------------------------//
//propagate from EX to MEM stage
//--------------------------------------------------------------------------------//
`ifdef KRV_HAS_DBG
wire flush_ex = breakpoint;
`else 
wire flush_ex = 1'b0;
`endif

wire ex_bubble = !dec_valid || ex_stall;
always@(posedge cpu_clk or negedge cpu_rstn)
begin
	if(!cpu_rstn)
	begin
		alu_result_mem <= {`DATA_WIDTH{1'b0}};
		ex_valid <= 1'b0;
	end
	else
	begin
		if(flush_ex)
		begin
			ex_valid <= 1'b0;
			alu_result_mem <= {`DATA_WIDTH{1'b0}};
		end
	   	else if(mem_ready)
	   	begin
	   	     	ex_valid <= 1'b1;           
			if(ex_bubble)
			begin
				alu_result_mem <= {`DATA_WIDTH{1'b0}};
			end
			else
			begin
	   	     		alu_result_mem <= alu_result_ex;
			end
	   	end
	end
end

`ifdef KRV_HAS_DBG
assign mem_addr_ex  = (load_ex || store_ex ) ? alu_result_ex : {`ADDR_WIDTH{1'b0}};
`endif
assign mem_addr_mem = (load_mem || store_mem ) ? alu_result_mem : {`ADDR_WIDTH{1'b0}};
always@(posedge cpu_clk or negedge cpu_rstn)
begin
	if(!cpu_rstn)
	begin
		rd_mem <= 32;
		load_mem <= 1'b0;
		store_mem <= 1'b0;
		mem_H_mem <= 1'b0;
		mem_B_mem <= 1'b0;
		mem_U_mem <= 1'b0;
		store_data_mem <= {`DATA_WIDTH{1'b0}};
	end
	else
	begin
		if(flush_ex)
		begin
			rd_mem <= 32;
			load_mem <= 1'b0;
			store_mem <= 1'b0;
			mem_H_mem <= 1'b0;
			mem_B_mem <= 1'b0;
			mem_U_mem <= 1'b0;
			store_data_mem <= {`DATA_WIDTH{1'b0}};
		end
	   	else if(mem_ready)
	   	begin
	   	     if(ex_bubble)
	   	     begin
	   	     	rd_mem <= 32;
	   	     	load_mem <= 1'b0;
	   	     	store_mem <= 1'b0;
	   	     	mem_H_mem <= 1'b0;
	   	     	mem_B_mem <= 1'b0;
	   	     	mem_U_mem <= 1'b0;
	   	     	store_data_mem <= {`DATA_WIDTH{1'b0}};
	   	     end
	   	     else
	   	     begin
	   	     	rd_mem <= rd_ex;
	   	     	load_mem <= load_ex;
	   	     	store_mem <= store_ex;
	   	     	mem_H_mem <= mem_H_ex;
	   	     	mem_B_mem <= mem_B_ex;
	   	     	mem_U_mem <= mem_U_ex;
	   	     	store_data_mem <= store_data_ex;
	   	     end
	   	end
	end
end

//Branch condition check
wire adder_res_neq0;
assign adder_res_neq0 = alu_sub_ex && (|adder_result);
wire adder_res_equ0;
assign adder_res_equ0 = ~adder_res_neq0;

wire branch_beq_taken;
wire branch_bne_taken;
wire branch_blt_taken;
wire branch_bge_taken;
wire branch_bltu_taken;
wire branch_bgeu_taken;
assign branch_beq_taken = beq_ex & (adder_res_equ0);
assign branch_bne_taken = bne_ex & (adder_res_neq0);
assign branch_blt_taken = blt_ex & (com_result);
assign branch_bge_taken = bge_ex & (!com_result);
assign branch_bltu_taken = bltu_ex & (ucom_result);
assign branch_bgeu_taken = bgeu_ex & (!ucom_result);
assign branch_taken_ex = branch_beq_taken | branch_bne_taken | branch_blt_taken | branch_bge_taken | branch_bltu_taken | branch_bgeu_taken;

wire ex_stall = (div_start && !div_done) 
`ifdef KRV_HAS_DBG
|| (dbg_mode && !(single_step_d2 || single_step_d3 || single_step_d4))
`endif
;
assign ex_ready = !ex_stall && mem_ready;

wire [31:0] ex_stall_cnt;
en_cnt u_ex_stall_cnt (.clk(cpu_clk), .rstn(cpu_rstn), .en(ex_stall), .cnt (ex_stall_cnt));


endmodule
