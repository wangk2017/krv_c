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
// File Name: 		dmem_ctrl.v				||
// Author:    		Kitty Wang				||
// Description: 						||
//	      		data memory control block              	|| 
// History:   							||
//                      2017/9/26 				||
//                      First version				||
//===============================================================
`include "top_defines.vh"
module dmem_ctrl (
//global signals
input wire cpu_clk,						//cpu clock
input wire cpu_rstn,						//cpu reset, active low

//interface with ALU
input load_ex,							//load at EX stage
input store_ex,							//store at EX stage
input load_mem,							//load at MEM stage
input store_mem,						//store at MEM stage
input wire mem_H_mem,						//halfword access at MEM stage
input wire mem_B_mem,						//byte access at MEM stage
input wire mem_U_mem,						//unsigned load at MEM stage
input wire [`DATA_WIDTH - 1 : 0]  store_data_mem,		//store data at MEM stage
input wire [`ADDR_WIDTH - 1 : 0] mem_addr_mem,   		//memory address at MEM stage
input wire [`RD_WIDTH:0] rd_mem,				//rd  at MEM stage
input wire [`DATA_WIDTH - 1 : 0] alu_result_mem,		//alu result at MEM stage	
input wire ex_valid,						//alu result valid signal at MEM stage	
output wire mem_ready,

//interface with wb_ctrl
output reg [`RD_WIDTH:0] rd_wb,					//rd at WB stage
output reg [`DATA_WIDTH - 1 : 0] alu_result_wb,			//alu result at WB stage	       	
output reg alu_result_valid_wb,		       			//alu result valid signal at WB stage	 	
output reg load_wb,						//load at WB stage
output reg [`DATA_WIDTH - 1 : 0] load_data_wb,			//load data at WB stage
output reg load_data_valid_wb,					//load data valid at WB stage
input wire wb_ready,

//interface with dec
output wire mem_wb_data_valid,			 		//dmem data valid
output wire [`DATA_WIDTH - 1 : 0] data_mem,			//forwarding result at MEM stage back to DEC stage 
output wire load_wait_data,					//load instruction is waiting for data valid from dmem

//interface with DTCM block
input wire dtcm_en,						//DTCM enable signal
input wire [`ADDR_WIDTH - 1 : 0] dtcm_start_addr,		//DTCM start address
output wire data_dtcm_access,					//DTCM access
input wire data_dtcm_ready,					//DTCM access
output wire data_dtcm_rd0_wr1,					//DTCM cmd read: 0 write:1
output wire [3:0] data_dtcm_byte_strobe,			//DTCM byte strobe
output wire [`DATA_WIDTH - 1 : 0]  data_dtcm_write_data,	//DTCM write data
output wire [`ADDR_WIDTH - 1 : 0] data_dtcm_addr,		//DTCM access address
input wire [`DATA_WIDTH - 1 : 0] data_dtcm_read_data,		//DTCM read data
input wire data_dtcm_read_data_valid,				//DTCM read data valid

//interface with DAHB block
output wire DAHB_access,					//DAHB access
output wire DAHB_rd0_wr1,					//DAHB cmd read: 0 write:1
output wire [2:0] DAHB_size,					//DAHB size 
output wire [`DATA_WIDTH - 1 : 0] DAHB_write_data,		//DAHB write data
output wire [`ADDR_WIDTH - 1 : 0] DAHB_addr,			//DAHB access address
input wire DAHB_trans_buffer_full,				//DAHB transfer buffer full
input wire [`DATA_WIDTH - 1 : 0] DAHB_read_data,		//DAHB read data
input wire DAHB_read_data_valid					//DAHB read data valid
);


//--------------------------------------------------------------------------------//
//Handshake
//--------------------------------------------------------------------------------//
wire mem_bubble = !ex_valid || dmem_stall;
reg load_mem_r;
always @ (posedge cpu_clk or negedge cpu_rstn)
begin
	if(!cpu_rstn)
	begin
		load_mem_r <= 1'b0;
	end
	else
	begin
		if(!load_stall)
		load_mem_r <= 1'b0;
		else if(load_mem)
		load_mem_r <= 1'b1;
	end
end

//NOTE: memory access should be aligned for now!
//--------------------------------------------------------------------------------//
//Address decode
//--------------------------------------------------------------------------------//
wire mem_access;
assign mem_access = (load_mem || store_mem) && (!load_wait_data_r);

//wire addr_itcm;
wire addr_dtcm;
wire addr_AHB;

`ifdef KRV_HAS_DTCM
assign addr_dtcm = dtcm_en && (mem_addr_mem >= dtcm_start_addr) && (mem_addr_mem < (dtcm_start_addr + `DTCM_SIZE));
`else
assign addr_dtcm = 1'b0;
`endif

assign addr_AHB = ~(addr_dtcm );

//reg addr_itcm_r;
reg addr_dtcm_r;
reg addr_AHB_r;

always @ (posedge cpu_clk or negedge cpu_rstn)
begin
	if(!cpu_rstn)
	begin
		addr_dtcm_r <= 1'b0;
		addr_AHB_r <= 1'b0;
	end
	else
	begin
		addr_dtcm_r <= addr_dtcm;
		addr_AHB_r <= addr_AHB;
	end
end


//-----------------//
//Store
//-----------------//

wire rd0_wr1;								//read: 0 write:1
reg [`DATA_WIDTH - 1 : 0]  mem_write_data;
wire [3:0] mem_byte_strobe;


assign mem_byte_strobe = mem_B_mem ? (4'b0001<<mem_addr_mem[1:0]) : 		//for byte access
			(mem_H_mem ? (4'b0011<<{mem_addr_mem[1],1'b0}) : 	//for half-word access
			4'b1111);				   		//for word access

reg mem_U_mem_r;
reg mem_B_mem_r;
reg mem_H_mem_r;
reg [3:0] mem_byte_strobe_r;
always @ (posedge cpu_clk or negedge cpu_rstn)
begin
	if(!cpu_rstn)
	begin
		mem_byte_strobe_r <= 4'h0;
		mem_U_mem_r <= 1'b0;
		mem_H_mem_r <= 1'b0;
		mem_B_mem_r <= 1'b0;
	end
	else
	begin
		mem_byte_strobe_r <= mem_byte_strobe;
		mem_U_mem_r <= mem_U_mem;
		mem_H_mem_r <= mem_H_mem;
		mem_B_mem_r <= mem_B_mem;
	end
end

assign rd0_wr1 = store_mem;

//generate write data for store
reg [`DATA_WIDTH - 1 : 0]  store_data_for_sb;
reg [`DATA_WIDTH - 1 : 0]  store_data_for_sh;

always @ *
begin
	case (mem_byte_strobe)
		4'b0001:  store_data_for_sb = {24'h0,store_data_mem[7:0]};
		4'b0010:  store_data_for_sb = {16'h0,store_data_mem[7:0], 8'h0};
		4'b0100:  store_data_for_sb = {8'h0,store_data_mem[7:0], 16'h0};
		4'b1000:  store_data_for_sb = {store_data_mem[7:0], 24'h0};
		default:  store_data_for_sb = 32'h0;
	endcase
end


always @ *
begin
	case (mem_byte_strobe)
		4'b0011:  store_data_for_sh = {16'h0,store_data_mem[15:0]};
		4'b1100:  store_data_for_sh = {store_data_mem[15:0], 16'h0};
		default:  store_data_for_sh = 32'h0;
	endcase
end

always @ *
begin
	case ({mem_H_mem,mem_B_mem})
	2'b00: mem_write_data = store_data_mem;	 	 //for word access
	2'b01: mem_write_data = store_data_for_sb;	 //for byte access
	2'b10: mem_write_data = store_data_for_sh;	 //for half-word access
	default: mem_write_data = {`DATA_WIDTH{1'b0}};
	endcase
end			


assign data_dtcm_access 	= mem_access && addr_dtcm; 
assign data_dtcm_rd0_wr1 	= rd0_wr1;
assign data_dtcm_write_data 	= mem_write_data;
assign data_dtcm_addr 		= mem_addr_mem - dtcm_start_addr;
assign data_dtcm_byte_strobe 	= mem_byte_strobe;

assign DAHB_access 		= mem_access && addr_AHB; 
assign DAHB_rd0_wr1 		= rd0_wr1;
assign DAHB_write_data 		= mem_write_data;
assign DAHB_addr 		= mem_addr_mem;
assign DAHB_size 		= mem_B_mem ? 3'b000 : (mem_H_mem ? 3'b001 : 3'b010);

//------------------//
//Load 
//------------------//
wire [`DATA_WIDTH - 1 : 0] mem_read_data;
assign mem_read_data = data_dtcm_read_data_valid ? data_dtcm_read_data : (DAHB_read_data_valid ? DAHB_read_data : (/*data_itcm_read_data_valid ? data_itcm_read_data :*/ {`DATA_WIDTH{1'b0}}));

wire load_data_sign_bit;
assign load_data_sign_bit = mem_byte_strobe_r[3]? mem_read_data[31] : 
			   (mem_byte_strobe_r[2]? mem_read_data[23] : 
			   (mem_byte_strobe_r[1]? mem_read_data[15] :
			    			mem_read_data[7]));

//generate read data for load
reg [`DATA_WIDTH - 1 : 0] mem_wb_data;
reg [`DATA_WIDTH - 1 : 0] mem_wb_data_for_lb;
reg [`DATA_WIDTH - 1 : 0] mem_wb_data_for_lh;
reg [`DATA_WIDTH - 1 : 0] mem_wb_data_for_lbu;
reg [`DATA_WIDTH - 1 : 0] mem_wb_data_for_lhu;

always @ *
begin
	case(mem_byte_strobe_r)
		4'b0001: mem_wb_data_for_lb = {{24{load_data_sign_bit}}, mem_read_data[7:0]};
		4'b0010: mem_wb_data_for_lb = {{24{load_data_sign_bit}}, mem_read_data[15:8]};
		4'b0100: mem_wb_data_for_lb = {{24{load_data_sign_bit}}, mem_read_data[23:16]};
		4'b1000: mem_wb_data_for_lb = {{24{load_data_sign_bit}}, mem_read_data[31:24]};
		default: mem_wb_data_for_lb = {`DATA_WIDTH{1'b0}};
	endcase
end

always @ *
begin
	case(mem_byte_strobe_r)
		4'b0001: mem_wb_data_for_lbu = {{24{1'b0}}, mem_read_data[7:0]};
		4'b0010: mem_wb_data_for_lbu = {{24{1'b0}}, mem_read_data[15:8]};
		4'b0100: mem_wb_data_for_lbu = {{24{1'b0}}, mem_read_data[23:16]};
		4'b1000: mem_wb_data_for_lbu = {{24{1'b0}}, mem_read_data[31:24]};
		default: mem_wb_data_for_lbu = {`DATA_WIDTH{1'b0}};
	endcase
end

always @ *
begin
	case(mem_byte_strobe_r)
		4'b0011: mem_wb_data_for_lh = {{16{load_data_sign_bit}}, mem_read_data[15:0]};
		4'b1100: mem_wb_data_for_lh = {{16{load_data_sign_bit}}, mem_read_data[31:16]};
		default: mem_wb_data_for_lh = {`DATA_WIDTH{1'b0}};
	endcase
end

always @ *
begin
	case(mem_byte_strobe_r)
		4'b0011: mem_wb_data_for_lhu = {{16{1'b0}}, mem_read_data[15:0]};
		4'b1100: mem_wb_data_for_lhu = {{16{1'b0}}, mem_read_data[31:16]};
		default: mem_wb_data_for_lhu = {`DATA_WIDTH{1'b0}};
	endcase
end


always @ *
begin
	if (mem_U_mem_r)
	begin
		case ({mem_H_mem_r,mem_B_mem_r})
		2'b00: mem_wb_data = mem_read_data;		 //for word access
		2'b01: mem_wb_data = mem_wb_data_for_lbu;	 //for byte access
		2'b10: mem_wb_data = mem_wb_data_for_lhu;	 //for half-word access
		default: mem_wb_data = {`DATA_WIDTH{1'b0}};
		endcase
	end
	else
	begin
		case ({mem_H_mem_r,mem_B_mem_r})
		2'b00: mem_wb_data = mem_read_data;		 //for word access
		2'b01: mem_wb_data = mem_wb_data_for_lb;	 //for byte access
		2'b10: mem_wb_data = mem_wb_data_for_lh;	 //for half-word access
		default: mem_wb_data = {`DATA_WIDTH{1'b0}};
		endcase
	end

end

assign mem_wb_data_valid = (addr_dtcm_r && data_dtcm_read_data_valid) | (addr_AHB_r && DAHB_read_data_valid)/* | (addr_itcm_r &&  data_itcm_read_data_valid)*/;

 
//--------------------------------------------//
//data propagate to write back
//--------------------------------------------//


always@(posedge cpu_clk or negedge cpu_rstn)
begin
	if(~cpu_rstn)
	begin
		alu_result_wb <= {`DATA_WIDTH{1'b0}};
		alu_result_valid_wb <= 1'b0;
		load_data_wb <= {`DATA_WIDTH{1'b0}};
		load_data_valid_wb <= 1'b0;
	end
	else
	begin
		if(mem_bubble)
		begin
			alu_result_wb <= {`DATA_WIDTH{1'b0}};
			alu_result_valid_wb <= 1'b0;
			load_data_wb <= {`DATA_WIDTH{1'b0}};
			load_data_valid_wb <= 1'b0;
		end
		else
		begin
			alu_result_wb <= alu_result_mem;
			alu_result_valid_wb <= !(load_mem || store_mem);
			load_data_wb <= mem_wb_data;
			load_data_valid_wb <= mem_wb_data_valid;
		end
	end
end
always@(posedge cpu_clk or negedge cpu_rstn)
begin
	if(~cpu_rstn)
	begin
		rd_wb <= {1'b1,{`RD_WIDTH{1'b0}}};
	end
	else
	begin
		if(mem_bubble)
		begin
			rd_wb <= {1'b1,{`RD_WIDTH{1'b0}}};
		end
		else
		begin
			rd_wb <= rd_mem;
		end
	end
end


always@(posedge cpu_clk or negedge cpu_rstn)
begin
	if(~cpu_rstn)
	begin
		load_wb <= 1'b0;
	end
	else
	begin
		if(mem_bubble)
		begin
			load_wb <= 1'b0;
		end
		else
		begin
			load_wb <= load_mem;
		end
	end
end


//--------------------------------------------//
//forwarding data to dec for data dependency
//--------------------------------------------//
assign data_mem = (load_mem || load_mem_r)? mem_wb_data : alu_result_mem;

//--------------------------------------------//
//MEM stage stall condition 
//--------------------------------------------//
reg load_wait_data_r;
assign load_wait_data = load_mem || load_wait_data_r;
always@(posedge cpu_clk or negedge cpu_rstn)
begin
	if(~cpu_rstn)
	begin
		load_wait_data_r <= 1'b0;
	end
	else 
	begin
		if(mem_wb_data_valid)
		begin
			load_wait_data_r <= 1'b0;
		end
		else if(load_mem)
		begin
			load_wait_data_r <= 1'b1;
		end
	end
end

wire load_stall = (load_mem & (!mem_wb_data_valid));
wire store_stall = (store_mem && ((addr_AHB && DAHB_trans_buffer_full) || (addr_dtcm && !data_dtcm_ready)));

wire dmem_stall =  (load_stall || store_stall);
assign mem_ready = !dmem_stall && wb_ready;

//performance counter
wire [31:0] load_stall_cnt;
en_cnt u_load_stall_cnt (.clk(cpu_clk), .rstn(cpu_rstn), .en(load_stall), .cnt (load_stall_cnt));

wire [31:0] store_stall_cnt;
en_cnt u_store_stall_cnt (.clk(cpu_clk), .rstn(cpu_rstn), .en(store_stall), .cnt (store_stall_cnt));

endmodule
