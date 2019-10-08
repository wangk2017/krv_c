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
// File Name: 		uart_rx.v				||
// Author:    		Kitty Wang				||
// Description: 						||
//	      		UART Receive control block		||
// History:   		2019.09.30				||
//                      First version				||
//===============================================================

`include "top_defines.vh"


module uart_rx(
input 		PCLK,
input        	PRESETN,
input 		UART_RX,
input 		rx_sample_pulse,
input  		data_bits,
input 		parity_en,
input 		parity_odd0_even1,
input		rx_data_reg_rd,
output [7:0]    rx_data,
output  	rx_data_read_valid,
output 		rx_ready,
output		parity_err,
output		overflow
);


parameter UART_DATA_WIDTH = 8;
parameter UART_RX_FIFO_DEPTH = 8;
parameter UART_RX_FIFO_PTR_WIDTH = $clog2(UART_RX_FIFO_DEPTH);

//RX sample
reg rx_d0;
reg rx_d1;

always @ (posedge PCLK or negedge PRESETN)
begin
	if(!PRESETN)
	begin
		rx_d0 <= 1'b1;
		rx_d1 <= 1'b1;
	end
	else
	begin
		rx_d0 <= UART_RX;
		rx_d1 <= rx_d0;
	end
end


//UART receive FSM
localparam UART_RX_IDLE  	= 3'b000;
localparam UART_RX_START 	= 3'b001;
localparam UART_RX_DATA  	= 3'b010;
localparam UART_RX_PARITY  	= 3'b011;
localparam UART_RX_STOP  	= 3'b100;

reg[2:0] uart_rx_state, uart_rx_next_state;

wire uart_rx_idle_stage = (uart_rx_state == UART_RX_IDLE);
wire uart_rx_data_stage = (uart_rx_state == UART_RX_DATA);
wire uart_rx_parity_stage = (uart_rx_state == UART_RX_PARITY);

reg[3:0] sample_cnt;
always @ (posedge PCLK or negedge PRESETN)
begin
	if(!PRESETN)
	begin
		sample_cnt <= 4'h0;
	end
	else
	begin
		if((uart_rx_idle_stage && !rx_d1) || !uart_rx_idle_stage)
		begin
			if(rx_sample_pulse)
			begin
				if(sample_cnt == 4'hf)
				sample_cnt <= 4'h0;
				else
				sample_cnt <= sample_cnt + 4'b1;
			end
		end
		else
		begin
			sample_cnt <= 4'h0;
		end
	end
end

wire rx_sample_point = (sample_cnt == 3'h7) && rx_sample_pulse;
wire rx_baud_pulse = (sample_cnt == 4'hf) && rx_sample_pulse;

reg [2:0] rx_data_bit_cnt;
reg last_sample;
always @ (posedge PCLK or negedge PRESETN)
begin
	if(!PRESETN)
	begin
		last_sample <= 1'b0;
	end
	else
	begin
		if(!uart_rx_data_stage)
		begin
			last_sample <= 1'b0;
		end
		else if((rx_data_bit_cnt == 3'h6 + data_bits) && rx_sample_point)
		begin
			last_sample <= 1'b1;
		end
	end
end

wire data_rx_done = last_sample && rx_baud_pulse;

//rx_data_bit_cnt
always @ (posedge PCLK or negedge PRESETN)
begin
	if(!PRESETN)
	begin
		rx_data_bit_cnt <= 3'h0;
	end
	else
	begin
		if(data_rx_done || !uart_rx_data_stage)
		rx_data_bit_cnt <= 3'h0;
		else if(uart_rx_data_stage && rx_sample_point)
		rx_data_bit_cnt <= rx_data_bit_cnt + 3'h1;
	end
end



always @ (posedge PCLK or negedge PRESETN)
begin
	if(!PRESETN)
	begin
		uart_rx_state <= UART_RX_IDLE;
	end
	else
	begin
		uart_rx_state <= uart_rx_next_state;
	end
end

always @*
begin
		case(uart_rx_state)
		UART_RX_IDLE: begin
			if(!rx_d1)
			uart_rx_next_state = UART_RX_START;
			else
			uart_rx_next_state = UART_RX_IDLE;
		end
		UART_RX_START: begin
			if(rx_sample_point && rx_d1)
			uart_rx_next_state = UART_RX_IDLE;
			else if(rx_baud_pulse)
			uart_rx_next_state = UART_RX_DATA;
			else
			uart_rx_next_state = UART_RX_START;
		end
		UART_RX_DATA: begin
			if(data_rx_done)
			begin
				if(parity_en)
				uart_rx_next_state = UART_RX_PARITY;
				else
				uart_rx_next_state = UART_RX_STOP;	
			end
			else
			uart_rx_next_state = UART_RX_DATA;
		end
		UART_RX_PARITY: begin
			if(rx_baud_pulse)
			uart_rx_next_state = UART_RX_STOP;	
			else
			uart_rx_next_state = UART_RX_PARITY;
		end
		UART_RX_STOP: begin
			if(rx_baud_pulse)
			uart_rx_next_state = UART_RX_IDLE;	
			else
			uart_rx_next_state = UART_RX_STOP;	
		end
		default: begin
			uart_rx_next_state = UART_RX_IDLE;	
		end
		endcase
end



reg[7:0] shift_rx_data;
always @ (posedge PCLK or negedge PRESETN)
begin
	if(!PRESETN)
	begin
		shift_rx_data <= 8'h0;
	end
	else if(uart_rx_data_stage)
	begin
		if(rx_sample_point)
		shift_rx_data <= {rx_d1,shift_rx_data[7:1]};
	end
	else
	begin
		shift_rx_data <= 8'h0;
	end
end	

reg parity_bit;
always @ (posedge PCLK or negedge PRESETN)
begin
	if(!PRESETN)
	begin
		parity_bit <= 1'b0;
	end
	else if(uart_rx_parity_stage)
	begin
		if(rx_sample_point)
		parity_bit <= rx_d1;
	end
end	

assign parity_err = parity_en && ((parity_odd0_even1 && (~^(shift_rx_data))) || (!parity_odd0_even1 && (^(shift_rx_data))));

wire uart_rx_buf_rd_valid;
wire [7:0] uart_rx_buf_rd_data;
wire uart_rx_buf_full;
wire uart_rx_buf_empty;



sync_fifo #(.DATA_WIDTH (UART_DATA_WIDTH), .FIFO_DEPTH(UART_RX_FIFO_DEPTH),.PTR_WIDTH(UART_RX_FIFO_PTR_WIDTH))  uart_rx_buf(
//write side signals
.wr_clk		(PCLK),
.wr_rstn	(PRESETN),
.wr_valid	(data_rx_done),
.wr_data	(shift_rx_data),
//read side signals
.rd_clk		(PCLK),
.rd_rstn	(PRESETN),
.rd_ready	(rx_data_reg_rd),
.rd_valid	(uart_rx_buf_rd_valid),
.rd_data	(uart_rx_buf_rd_data),
.full		(uart_rx_buf_full),
.empty		(uart_rx_buf_empty)
);

assign rx_data = uart_rx_buf_rd_valid ? uart_rx_buf_rd_data : 8'h0;
assign rx_data_read_valid = uart_rx_buf_rd_valid;
assign rx_ready = !uart_rx_buf_empty;
assign overflow = data_rx_done && uart_rx_buf_full;


endmodule
