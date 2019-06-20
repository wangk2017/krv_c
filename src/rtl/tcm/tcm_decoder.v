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

//===============================================================||
// File Name: 		tcm_decoder.v				 ||
// Author:    		Kitty Wang				 ||
// Description:   						 ||
//	      		decoder of tcm to be accessed by AHB     ||
// History:   							 ||
//===============================================================||

`include "top_defines.vh"

module tcm_decoder (
//AHB INTERFACE
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
output wire [1:0] HRESP,
output wire [`AHB_DATA_WIDTH - 1 : 0] HRDATA,

//tcm interface
input wire itcm_auto_load,
output wire AHB_itcm_access,
output wire AHB_dtcm_access,
output wire [`AHB_ADDR_WIDTH - 1 : 0] AHB_tcm_addr,
output wire [3:0] AHB_tcm_byte_strobe,
output wire AHB_tcm_rd0_wr1,
output wire [`DATA_WIDTH - 1 : 0] AHB_tcm_write_data,
input wire [`DATA_WIDTH - 1 : 0] AHB_itcm_read_data,
input wire AHB_itcm_read_data_valid,
input wire [`DATA_WIDTH - 1 : 0] AHB_dtcm_read_data,
input wire AHB_dtcm_read_data_valid,
output wire HSEL_flash,
input wire  HREADY_flash,
input wire [`DATA_WIDTH - 1 : 0] HRDATA_flash

);


wire [`DATA_WIDTH - 1 : 0] AHB_tcm_read_data;
wire AHB_tcm_read_data_valid;
wire valid_reg_access;

wire HREADY_tcm;

ahb2regbus #(.RD_DELAY_1_CYCLE(1),.IP_REG_END_OFFSET(12'hFFF))  u_ahb2regbus(
	//AHB IF
	.HCLK			(HCLK),
	.HRESETn		(HRESETn),
	.HSEL			(HSEL),
	.HADDR			(HADDR),
	.HWRITE			(HWRITE),
	.HSIZE			(HSIZE),
	.HTRANS			(HTRANS),
	.HBURST			(HBURST),
	.HWDATA			(HWDATA),
	.HREADY			(HREADY_tcm),
	.HRESP			(HRESP),
	.HRDATA			(HRDATA),
	//IP reg bus
	.ip_read_data		(AHB_tcm_read_data),
	.ip_read_data_valid	(AHB_tcm_read_data_valid),
	.ip_write_data		(AHB_tcm_write_data),
	.ip_addr		(AHB_tcm_addr),
	.ip_byte_strobe		(AHB_tcm_byte_strobe),
	.valid_reg_access	(valid_reg_access),
	.ip_wr1_rd0		(AHB_tcm_rd0_wr1)
);

`ifdef KRV_HAS_ITCM
assign AHB_itcm_access = (!itcm_auto_load) && valid_reg_access && (AHB_tcm_addr >= `ITCM_START_ADDR) && (AHB_tcm_addr < `ITCM_START_ADDR + `ITCM_SIZE); 
wire HADDR_itcm_range = (!itcm_auto_load) && (HADDR >= `ITCM_START_ADDR) && (HADDR < `ITCM_START_ADDR + `ITCM_SIZE);
`else
assign AHB_itcm_access = 1'b0;
wire HADDR_itcm_range = 1'b0;
`endif


`ifdef KRV_HAS_DTCM
assign AHB_dtcm_access = valid_reg_access &&  (AHB_tcm_addr >= `DTCM_START_ADDR) && (AHB_tcm_addr < `DTCM_START_ADDR + `DTCM_SIZE); 
wire HADDR_dtcm_range = (HADDR >= `DTCM_START_ADDR) && (HADDR < `DTCM_START_ADDR + `DTCM_SIZE);
`else
assign AHB_dtcm_access = 1'b0;
wire HADDR_dtcm_range = 1'b0;
`endif

reg AHB_dtcm_access_r;
reg AHB_itcm_access_r;

always @(posedge HCLK or negedge HRESETn)
begin
	if(!HRESETn)
	begin
		AHB_dtcm_access_r <= 1'b0;
		AHB_itcm_access_r <= 1'b0;
	end
	else
	begin
		AHB_dtcm_access_r <= AHB_dtcm_access;
		AHB_itcm_access_r <= AHB_itcm_access;
	end
end

assign AHB_tcm_read_data = AHB_dtcm_access_r ? AHB_dtcm_read_data : (AHB_itcm_access_r ? AHB_itcm_read_data : HRDATA_flash);
assign AHB_tcm_read_data_valid = (AHB_dtcm_access || AHB_dtcm_access_r ) ? AHB_dtcm_read_data_valid : ((AHB_itcm_access || AHB_itcm_access_r)? AHB_itcm_read_data_valid : valid_reg_access);

assign HREADY = (AHB_dtcm_access || AHB_itcm_access ) ? HREADY_tcm : HREADY_flash;

assign HSEL_flash = HSEL && (!(HADDR_itcm_range || HADDR_dtcm_range));

endmodule
