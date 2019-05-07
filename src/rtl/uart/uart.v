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
// File Name: 		uart.v					||
// Author:    		Kitty Wang				||
// Description: 						||
//	      		UART 				    	|| 
// History:   		2019.04.25				||
//                      First version				||
//===============================================================

// uart
module uart(
// APB signals
input  [4:0] PADDR,
input        PCLK,
input        PENABLE,
input        PRESETN,
input        PSEL,
input  [7:0] PWDATA,
input        PWRITE,
output [7:0] PRDATA,
output       PREADY,
output	     PSLVERR,
// UART signals
input        RX,
output       TX,
output       UART_INT
);
//--------------------------------------------------------------------
// wires
//--------------------------------------------------------------------
wire 		tx_data_reg_wr;
wire [7:0] 	tx_data;
wire [7:0] 	rx_data;
wire [12:0] 	baud_val;
wire  		data_bits;
wire 		parity_en;
wire 		parity_odd0_even1;
wire 		rx_ready;
wire 		tx_ready;
wire 		parity_err;
wire 		overflow;
wire 		tx_baud_pulse;	
wire 		rx_sample_pulse;	


//UART registers
uart_regs u_uart_regs (
.PADDR				(PADDR		),
.PCLK				(PCLK		),
.PENABLE			(PENABLE	),
.PRESETN			(PRESETN	),
.PSEL				(PSEL		),
.PWDATA				(PWDATA		),
.PWRITE				(PWRITE		),
.PRDATA				(PRDATA		),
.PREADY				(PREADY		),
.PSLVERR			(PSLVERR	),
.tx_data_reg_wr			(tx_data_reg_wr		),
.tx_data			(tx_data		),
.rx_data			(rx_data		),
.baud_val			(baud_val		),
.data_bits			(data_bits		),
.parity_en			(parity_en		),
.parity_odd0_even1		(parity_odd0_even1	),
.rx_ready			(rx_ready		),
.tx_ready			(tx_ready		),
.parity_err			(parity_err		),
.overflow			(overflow		)
);


//UART baud clock generator
baud_clk_gen u_baud_clk_gen (
.PCLK				(PCLK		),
.PRESETN			(PRESETN	),
.baud_val			(baud_val	),
.tx_baud_pulse			(tx_baud_pulse	),
.rx_sample_pulse		(rx_sample_pulse)
);

//UART transmit control block
uart_tx u_uart_tx (
.PCLK				(PCLK		),
.PRESETN			(PRESETN	),
.tx_baud_pulse			(tx_baud_pulse	),
.tx_data_reg_wr			(tx_data_reg_wr		),
.tx_data			(tx_data		),
.data_bits			(data_bits		),
.parity_en			(parity_en		),
.parity_odd0_even1		(parity_odd0_even1	),
.UART_TX			(TX			),
.tx_ready			(tx_ready		)
);

//UART receive control block
uart_rx u_uart_rx (
);

endmodule
