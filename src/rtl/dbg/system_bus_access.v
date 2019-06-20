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
// File Name: 		system_bus_access.v			||
// Author:    		Kitty Wang				||
// Description: 						||
//	      		system bus access 	                ||
// History:   		2019.06.18				||
//                      First version				||
//===============================================================
`include "top_defines.vh"

module system_bus_access(
//AHB MASTER IF
input wire HCLK,
input wire HRESETn,
input wire HGRANT,
input wire HREADY,
input wire [1:0] HRESP,
input wire [`AHB_DATA_WIDTH - 1 : 0] HRDATA,
output wire HBUSREQ,
output wire HLOCK,
output wire [1:0] HTRANS,
output wire [`AHB_ADDR_WIDTH - 1 : 0] HADDR,
output wire HWRITE,
output wire [2:0] HSIZE,
output wire [2:0] HBURST,
output wire [3:0] HPROT,
output wire [`AHB_DATA_WIDTH - 1 : 0] HWDATA,

//dm global clock
input				sys_clk,
input				sys_rstn,

//interface with dm_regs block
input [`DM_REG_WIDTH - 1 : 0]	sbaddress0,
input				sbaddress0_update,
input [`DM_REG_WIDTH - 1 : 0]	sbdata0,
input				sbdata0_update,
input				sbdata0_rd,
output [`DM_REG_WIDTH - 1 : 0]	system_bus_read_data,
output 				system_bus_read_data_valid,
output				sbbusy,
input				sbreadonaddr,
input[2:0]			sbaccess,
input				sbreadondata,
output reg [2:0]		sberror,
input[2:0]			sberror_w1,
output reg 			sbbusyerror,
input				sbbusyerror_w1

);


parameter WAIT_FOR_GRANT_S 	= 2'b00;
parameter ADDR_S		= 2'b01;
parameter DATA_S		= 2'b10;


//Ignore CDC as HCLK and sys_clk use the same clock source
wire hwrite_i = sbdata0_update;
wire hbusreq_i = sbdata0_rd || sbdata0_update || (sbaddress0_update && sbreadonaddr) && !sbbusy;
wire [1:0] htrans_i = HGRANT ? `NONSEQ : `IDLE;
wire [2:0] hsize_i = sbaccess;

assign HBUSREQ 	= hbusreq_i;
assign HWRITE 	= hwrite_i;
assign HTRANS 	= htrans_i;
assign HADDR 	= sbaddress0;
assign HWDATA 	= sbdata0;
assign HSIZE 	= hsize_i;
assign HBURST 	= 3'b000;
assign HPROT 	= 4'b1111;

assign system_bus_read_data_valid = (state == DATA_S) && HREADY && !hwrite_r;
assign system_bus_read_data = HRDATA;


//AHB transfer FSM
reg[1:0] state, next_state;
reg hwrite_r;
reg hwrite;


always @ (posedge HCLK or negedge HRESETn)
begin
	if(!HRESETn)
	begin
		state <= WAIT_FOR_GRANT_S;
		hwrite_r <= 1'b0;
	end
	else
	begin
		state <= next_state;
		hwrite_r <= hwrite;
	end
end

always @ *
begin
	case(state)
		WAIT_FOR_GRANT_S: 
		begin
			if(HBUSREQ && HGRANT && HREADY)
			begin
				next_state = ADDR_S;
				hwrite = hwrite_i;
			end
			else
			begin
				next_state = WAIT_FOR_GRANT_S;
				hwrite = hwrite_r;
			end
		end
		ADDR_S:
		begin
			hwrite = hwrite_i;
			if(HREADY)
			begin
				next_state = DATA_S;
			end
			else
			begin
				next_state = ADDR_S;
			end
		end
		DATA_S:
		begin	
			hwrite = hwrite_r;
			if(HREADY)
			begin
				next_state = WAIT_FOR_GRANT_S;
			end
			else
			begin
				next_state = DATA_S;
			end
		end
		default:
		begin
			hwrite = hwrite_r;
			next_state = WAIT_FOR_GRANT_S;
		end
	endcase
end

assign sbbusy = (state != WAIT_FOR_GRANT_S);

always @ (posedge sys_clk or negedge sys_rstn)
begin
	if(!sys_rstn)
	begin
		sbbusyerror <= 1'b0;
	end
	else 
	begin
		if(sbbusyerror_w1)
		begin
			sbbusyerror <= 1'b0;
		end
		else if(sbbusy && (sbdata0_update || (sbaddress0_update && sbreadonaddr)))
		begin
			sbbusyerror <= 1'b1;
		end
	end
end

integer i;
always @ (posedge sys_clk or negedge sys_rstn)
begin
	if(!sys_rstn)
	begin
		sberror <= 3'h0;
	end
	else 
	begin
		if(|sberror_w1)
		begin
			for(i=0; i<3; i=i+1)
			begin
			if(sberror_w1[i])
				sberror[i] <= 1'b0;
			end
		end
		else if(hbusreq_i)
		begin
			if(hsize_i > 3'b10)
				sberror <= 3'h4;
			else
				sberror <= 3'h0;
		end
	end
end


endmodule

