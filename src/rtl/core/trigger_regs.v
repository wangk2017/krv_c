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
// File Name: 		trigger_regs.v				||
// Author:    		Kitty Wang				||
// Description: 						||
//	      		hardware trigger registers              ||
// History:   							||
//                      2019/5/27 				||
//                      First version				||
//===============================================================

`include "core_defines.vh"
`include "dbg_defines.vh"


module trigger_regs(
//global signals
input wire cpu_clk,					//cpu clock
input wire cpu_rstn,					//cpu reset, active low

//interface with dec for CSR access
input wire [11:0] csr_addr,				//csr access address
input wire mcsr_rd,					//mcsr read
input wire mcsr_wr,					//mcsr write
input wire valid_mcsr_rd,				//valid mcsr read
input wire valid_mcsr_wr,				//valid mcsr write
input wire mcsr_set,					//mcsr set
input wire mcsr_clr,					//mcsr clear
input wire [`DATA_WIDTH - 1 : 0] write_data,		//mcsr write data
output wire [`DATA_WIDTH - 1 : 0] read_data,		//mcsr read data
input [`DATA_WIDTH - 1 : 0] mctrl_rd_data,
output reg tselect,
output reg [`DATA_WIDTH - 1 : 0] tdata1,
output reg [`DATA_WIDTH - 1 : 0] tdata2_t0,
output reg [`DATA_WIDTH - 1 : 0] tdata3_t0,
output reg [`DATA_WIDTH - 1 : 0] tdata2_t1,
output reg [`DATA_WIDTH - 1 : 0] tdata3_t1


//`ifdef KRV_HAS_DBG
//debug interface
,
input				dbg_mode,
input				dbg_reg_access,
input 				dbg_wr1_rd0,
input[`CMD_REGNO_SIZE - 1 : 0]	dbg_regno,
input[`DATA_WIDTH - 1 : 0]	dbg_write_data,
output                     	dbg_read_data_valid,
output[`DATA_WIDTH - 1 : 0]	dbg_read_data,
output				dbg_wr
//`endif


);

//------------------------------------------------//
//For Debugger access 
//------------------------------------------------//
//`ifdef KRV_HAS_DBG
wire dbg_csrs_range = (dbg_regno >= 16'h0000) && (dbg_regno <= 16'h0fff);
wire dbg_csrs_access = dbg_reg_access && dbg_csrs_range;
assign dbg_wr = dbg_wr1_rd0  && dbg_csrs_access;
wire dbg_rd = !dbg_wr1_rd0 && dbg_csrs_access;
wire dbg_addr = dbg_regno[11:0];
assign dbg_read_data_valid = dbg_rd;
assign dbg_read_data = dbg_rd ? read_data : 32'h0;
//`else
/*
wire dbg_mode = 1'b0;
wire dbg_wr = 1'b0;
wire dbg_rd = 1'b0;
wire [`DATA_WIDTH - 1 : 0]	dbg_write_data = 32'h0;
wire dbg_addr = 12'h0;
*/
//`endif

//------------------------------------------------//
//Register address decode
//------------------------------------------------//

wire [11:0] csr_access_addr = dbg_csrs_access ? dbg_addr : csr_addr;

wire tselect_sel 	= (csr_access_addr == `TSELECT_ADDR);
wire tdata1_sel 	= (csr_access_addr == `TDATA1_ADDR);
wire tdata2_sel 	= (csr_access_addr == `TDATA2_ADDR);
wire tdata3_sel 	= (csr_access_addr == `TDATA3_ADDR);


//tselect -- Trigger Select 
//currently only two trigger is supported

always @ (posedge cpu_clk or negedge cpu_rstn)
begin
	if(!cpu_rstn)
	begin
		tselect <= 1'b0;
	end
	else
	begin
		if (dbg_wr && tselect_sel)
		begin
			tselect = dbg_write_data[0];
		end
		else if (tselect_sel & valid_mcsr_wr)
		begin
			if(mcsr_set)
			begin
				tselect <= tselect | write_data[0];
			end
			else if(mcsr_clr)
			begin
				tselect <= tselect & (~write_data[0]);
			end
			else
			begin
				tselect <= write_data[0];
			end
		end
	end
end


wire [`DATA_WIDTH - 1 : 0] tselect_rd_data;
assign tselect_rd_data = (tselect_sel)? {31'h0,tselect} : {`DATA_WIDTH{1'b0}};


//tdata1 -- Trigger Data1

always @ (posedge cpu_clk or negedge cpu_rstn)
begin
	if(!cpu_rstn)
	begin
		tdata1 <= 1'b0;
	end
	else
	begin
		if (dbg_wr && tdata1_sel)
		begin
			tdata1 = dbg_write_data;
		end
		else if (tdata1_sel && valid_mcsr_wr)
		begin
			if(mcsr_set)
			begin
				tdata1 <= tdata1 | write_data;
			end
			else if(mcsr_clr)
			begin
				tdata1 <= tdata1 & (~write_data);
			end
			else
			begin
				tdata1 <= write_data;
			end
		end
	end
end

wire data1_type = tdata1[`DATA_WIDTH - 1 : `DATA_WIDTH -4];
wire dmode = tdata1[`DATA_WIDTH - 5];

wire valid_tdata_wr = dmode ? (valid_mcsr_wr && dbg_mode) : valid_mcsr_wr;

wire [`DATA_WIDTH - 1 : 0] tdata1_rd_data;
assign tdata1_rd_data = (tdata1_sel)? ((data1_type == 2) ? mctrl_rd_data : tdata1) : {`DATA_WIDTH{1'b0}};



//tdata2 -- Trigger Data2

always @ (posedge cpu_clk or negedge cpu_rstn)
begin
	if(!cpu_rstn)
	begin
		tdata2_t0 <= 1'b0;
		tdata2_t1 <= 1'b0;
	end
	else
	begin
		if (dbg_wr && tdata2_sel)
		begin
			if(tselect)
			tdata2_t1 = dbg_write_data;
			else
			tdata2_t0 = dbg_write_data;
		end
		else if (tdata2_sel & valid_tdata_wr)
		begin
			if(mcsr_set)
			begin
				if(tselect)
				tdata2_t1 <= tdata2_t1 | write_data;
				else
				tdata2_t0 <= tdata2_t0 | write_data;
			end
			else if(mcsr_clr)
			begin
				if(tselect)
				tdata2_t1 <= tdata2_t1 & (~write_data);
				else
				tdata2_t0 <= tdata2_t0 & (~write_data);
			end
			else
			begin
				if(tselect)
				tdata2_t1 <= write_data;
				else
				tdata2_t0 <= write_data;
			end
		end
	end
end


wire [`DATA_WIDTH - 1 : 0] tdata2_rd_data;
assign tdata2_rd_data = (tdata2_sel)? (tselect ?  tdata2_t1 : tdata2_t0) : {`DATA_WIDTH{1'b0}};



//tdata3 -- Trigger Data3



always @ (posedge cpu_clk or negedge cpu_rstn)
begin
	if(!cpu_rstn)
	begin
		tdata3_t0 <= 1'b0;
		tdata3_t1 <= 1'b0;
	end
	else
	begin
		if (dbg_wr && tdata3_sel)
		begin
			if(tselect)
			tdata3_t1 = dbg_write_data;
			else
			tdata3_t0 = dbg_write_data;
		end
		else if (tdata3_sel & valid_tdata_wr)
		begin
			if(mcsr_set)
			begin
				if(tselect)
				tdata3_t1 <= tdata3_t1 | write_data;
				else
				tdata3_t0 <= tdata3_t0 | write_data;
			end
			else if(mcsr_clr)
			begin
				if(tselect)
				tdata3_t1 <= tdata3_t1 & (~write_data);
				else
				tdata3_t0 <= tdata3_t0 & (~write_data);
			end
			else
			begin
				if(tselect)
				tdata3_t1 <= write_data;
				else
				tdata3_t0 <= write_data;
			end
		end
	end
end


wire [`DATA_WIDTH - 1 : 0] tdata3_rd_data;
assign tdata3_rd_data = (tdata3_sel)? (tselect ?  tdata3_t1 : tdata3_t0) : {`DATA_WIDTH{1'b0}};

//Combine trigger_regs read data
assign read_data = {`DATA_WIDTH{valid_mcsr_rd || dbg_rd}} & 
		(tselect_rd_data |
		 tdata1_rd_data  |
		 tdata2_rd_data  |
		 tdata3_rd_data  
		 );




endmodule
