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
// File Name: 		ahb2regbus.v				||
// Author:    		Kitty Wang				||
// Description: 						||
//	      		ahb bus slave interface                	|| 
// History:   							||
//                      2017/10/24 				||
//                      First version				||
//===============================================================

`include "ahb_defines.vh"
module ahb2regbus (
	//AHB IF
	input wire HCLK,
	input wire HRESETn,
	input wire HSEL,
	input wire [`AHB_ADDR_WIDTH - 1 : 0] HADDR,
	input wire HWRITE,
	input wire [2:0] HSIZE,
	input wire [1:0] HTRANS,
	input wire [2:0] HBURST,
	input wire [`AHB_DATA_WIDTH - 1 : 0] HWDATA,
	output wire HREADY,
	output reg [1:0] HRESP,
	output wire [`AHB_DATA_WIDTH - 1 : 0] HRDATA,
	//IP reg bus
	input wire [`AHB_DATA_WIDTH - 1 : 0] ip_read_data,
	input wire ip_read_data_valid,
	output wire [`AHB_DATA_WIDTH - 1 : 0] ip_write_data,
	output reg [`AHB_ADDR_WIDTH - 1 : 0] ip_addr,
	output reg [3:0] ip_byte_strobe,
	output reg valid_reg_access,
	output reg ip_wr1_rd0
);

parameter IP_REG_START_OFFSET = 12'h000;
parameter IP_REG_END_OFFSET = 12'h148;
parameter IP_OFFSET_RANGE_R = 11;
parameter IP_OFFSET_RANGE_L = 0;

//parameter RD_DELAY_1_CYCLE = 0;

//Logic Start
//IP register is always ready to receive any ahb transaction after reset

//wire rd_delay_1 = RD_DELAY_1_CYCLE;

assign HREADY = ip_read_data_valid;

/*
always @ (posedge HCLK or negedge HRESETn)
begin
	if(!HRESETn)
	begin
		hready_r <= 1'b1;
	end
	else
	begin
		if(rd_delay_1)
		begin
			if(HSEL && !HWRITE &&  hready_r)
				hready_r <= 1'b0;
			else
				hready_r <= 1'b1;
		end
		else 
		begin
			hready_r <= 1'b1;
		end
	end
end
*/

wire valid_ahb_addr;
wire valid_ahb_ctrl;
wire valid_addr_phase;
assign valid_ahb_addr = HSEL && ((HADDR[IP_OFFSET_RANGE_R : IP_OFFSET_RANGE_L] >= IP_REG_START_OFFSET) && (HADDR[IP_OFFSET_RANGE_R : IP_OFFSET_RANGE_L] <= IP_REG_END_OFFSET));
assign valid_ahb_ctrl = HSEL && (HTRANS ==`NONSEQ);
assign valid_addr_phase = valid_ahb_addr && valid_ahb_ctrl;

always @ (posedge HCLK or negedge HRESETn)
begin
	if(!HRESETn)
	begin
		valid_reg_access <= 1'b0;
	end
	else
	begin
		if(valid_addr_phase)
		begin
			valid_reg_access <= 1'b1;
		end
		else
		begin
			valid_reg_access <= 1'b0;
		end
	end
end


reg[2:0] ip_size;

always @ (posedge HCLK or negedge HRESETn)
begin
	if(!HRESETn)
	begin
		ip_addr <= {`AHB_ADDR_WIDTH{1'b0}};
		ip_size <= 3'h0;
		ip_wr1_rd0 <= 1'b0;
	end
	else
	begin
		if(valid_addr_phase)
		begin
			ip_addr <= HADDR;
			ip_size <= HSIZE;
			ip_wr1_rd0 <= HWRITE;
		end
		else
		begin
			ip_addr <= {`AHB_ADDR_WIDTH{1'b0}};
			ip_size <= 3'h0;
			ip_wr1_rd0 <= 1'b0;
		end
	end
end

always @ *
begin
	case (ip_size)
	3'h0: ip_byte_strobe = 4'b0001 << ip_addr[1:0];
	3'h1: ip_byte_strobe = 4'b0011 << {ip_addr[1],1'b0};
	3'h2: ip_byte_strobe = 4'b1111;
	default: ip_byte_strobe = 4'b0000;
	endcase
end

always @ (posedge HCLK or negedge HRESETn)
begin
	if(!HRESETn)
	begin
		HRESP <= `OKAY;
	end
	else
	begin
		if(HSEL && (!(valid_ahb_addr && valid_ahb_ctrl)))
		begin
			HRESP <= `ERROR;
		end
		else
		begin
			HRESP <= `OKAY;
		end
	end
end

assign ip_write_data = HWDATA;

assign HRDATA = ip_read_data;

endmodule
