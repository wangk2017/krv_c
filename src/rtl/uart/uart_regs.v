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
// File Name: 		uart_regs.v				||
// Author:    		Kitty Wang				||
// Description: 						||
//	      		UART registers			    	|| 
// History:   		2019.04.25				||
//                      First version				||
//===============================================================

module uart_regs(
// APB signals
input  [4:0] 	PADDR,
input        	PCLK,
input        	PENABLE,
input        	PRESETN,
input        	PSEL,
input  [7:0] 	PWDATA,
input        	PWRITE,
output [7:0] 	PRDATA,
output       	PREADY,
output 		PSLVERR,
//registers 
output  	tx_data_reg_wr,
output [7:0] 	tx_data,
output [12:0] 	baud_val,
output  	data_bits,
output 		parity_en,
output 		parity_odd0_even1,
input  [7:0] 	rx_data,
input 		rx_ready,
input 		tx_ready,
input 		parity_err,
input 		overflow
);

//------------------------------------------------------
//registers offset
//------------------------------------------------------
`define TX_DATA_REG_OFFSET 3'h0
`define RX_DATA_REG_OFFSET 3'h1
`define CONFIG1_REG_OFFSET 3'h2
`define CONFIG2_REG_OFFSET 3'h3
`define STATUS_REG_OFFSET 3'h4


//------------------------------------------------------
//signals 
//------------------------------------------------------

reg  [7:0] 	config1_reg;
reg  [7:0] 	config2_reg;

assign  tx_data = PWDATA;
assign 	baud_val = {config2_reg[7:3],config1_reg};
assign 	data_bits = config2_reg[0];
assign  parity_en = config2_reg[1];
assign  parity_odd0_even1 = config2_reg[2];


//tx_data reg(fifo) is maintained in uart_tx block
wire tx_data_reg_sel = PADDR[4:2] == `TX_DATA_REG_OFFSET;
assign tx_data_reg_wr = PSEL && PWRITE && PENABLE && tx_data_reg_sel;
wire [7:0] tx_data_read_data = 8'h0;

//rx_data reg is maintained in uart_rx block
wire rx_data_reg_sel = PADDR[4:2] == `RX_DATA_REG_OFFSET;
wire [7:0] rx_data_read_data = rx_data_reg_sel ? rx_data : 8'h0;

//config1_reg
wire config1_reg_sel = PADDR[4:2] == `CONFIG1_REG_OFFSET;
wire config1_reg_wr = PSEL && PWRITE && PENABLE && config1_reg_sel;
always@(posedge PCLK or negedge PRESETN)
begin
	if(!PRESETN)
	begin
		config1_reg <= 8'h0;
	end
	else
	begin
		if(config1_reg_wr)
		begin
			config1_reg <= PWDATA;
		end
		else
		begin
			config1_reg <= config1_reg;
		end
	end
end

wire [7:0] config1_read_data = config1_reg_sel ? config1_reg : 8'h0;

//config2_reg
wire config2_reg_sel = PADDR[4:2] == `CONFIG2_REG_OFFSET;
wire config2_reg_wr = PSEL && PWRITE && PENABLE && config2_reg_sel;
always@(posedge PCLK or negedge PRESETN)
begin
	if(!PRESETN)
	begin
		config2_reg <= 8'h0;
	end
	else
	begin
		if(config2_reg_wr)
		begin
			config2_reg <= PWDATA;
		end
		else
		begin
			config2_reg <= config2_reg;
		end
	end
end

wire [7:0] config2_read_data = config2_reg_sel ? config2_reg : 8'h0;

//status_reg
wire status_reg = {4'b0,overflow,parity_err,rx_ready,tx_ready};
wire status_reg_sel = PADDR[4:2] == `STATUS_REG_OFFSET;
wire [7:0] status_read_data = status_reg_sel ? status_reg : 8'h0;


wire valid_reg_read = PSEL && !PENABLE && !PWRITE;
wire [7:0] NxtPRDATA = {8{valid_reg_read}} & 
			(tx_data_read_data 	|
			 rx_data_read_data	|
			 config1_read_data	|
			 config2_read_data	|
			 status_read_data	
			);
reg [7:0] iPRDATA;

always@(posedge PCLK or negedge PRESETN)
begin
	if(!PRESETN)
	begin
		iPRDATA <= 8'h0;
	end
	else
	begin
		iPRDATA <= NxtPRDATA;
	end
end

assign PRDATA = iPRDATA;
assign PREADY = 1'b1;
assign PSLVERR= 1'b0;

endmodule


