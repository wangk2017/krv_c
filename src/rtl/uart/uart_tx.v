//==============================================================||
// File Name: 		uart_tx.v				||
// Author:    		Kitty Wang				||
// Description: 						||
//	      		UART transmit control block		||
// History:   		2019.04.26				||
//                      First version				||
//===============================================================

module uart_tx(
input        	PCLK,
input        	PRESETN,
input 		tx_baud_pulse,
input  		tx_data_reg_wr,
input [7:0] 	tx_data,
input  		data_bits,
input 		parity_en,
input 		parity_odd0_even1,
output	reg	UART_TX,
output		tx_ready
);

parameter UART_DATA_WIDTH = 8;
parameter UART_TX_FIFO_DEPTH = 8;
parameter UART_TX_FIFO_PTR_WIDTH = 4;

wire uart_tx_buf_rd_ready;
wire uart_tx_buf_rd_valid;
wire [7:0] uart_tx_buf_rd_data;
wire uart_tx_buf_full;
wire uart_tx_buf_empty;

sync_fifo #(.DATA_WIDTH (UART_DATA_WIDTH), .FIFO_DEPTH(UART_TX_FIFO_DEPTH),.PTR_WIDTH(UART_TX_FIFO_PTR_WIDTH))  UARTT_TX_BUF(
//write side signals
.wr_clk		(PCLK),
.wr_rstn	(PRESETN),
.wr_valid	(tx_data_reg_wr),
.wr_data	(tx_data),
//read side signals
.rd_clk		(PCLK),
.rd_rstn	(PRESETN),
.rd_ready	(uart_tx_buf_rd_ready),
.rd_valid	(uart_tx_buf_rd_valid),
.rd_data	(uart_tx_buf_rd_data),
.full		(uart_tx_buf_full),
.empty		(uart_tx_buf_empty)
);


//tx fsm
parameter UART_TX_IDLE 		= 3'b000;
parameter UART_TX_START 	= 3'b001;
parameter UART_TX_DATA 		= 3'b010;
parameter UART_TX_PARITY 	= 3'b011;
parameter UART_TX_STOP 		= 3'b100;

reg [2:0] tx_data_bit_cnt;
wire data_tx_done = (tx_data_bit_cnt == 3'h6 + data_bits);

reg [2:0] uart_tx_state, uart_tx_next_state;

assign uart_tx_buf_rd_ready = (uart_tx_state == UART_TX_IDLE) && !uart_tx_buf_empty && tx_baud_pulse;

always @ (posedge PCLK or negedge PRESETN)
begin
	if(!PRESETN)
	begin
		uart_tx_state <= UART_TX_IDLE;
	end
	else
	begin
			uart_tx_state <= uart_tx_next_state;
	end
end

always @ *
begin
	if(tx_baud_pulse)
	begin
		case (uart_tx_state)
		UART_TX_IDLE: begin
			if(uart_tx_buf_rd_ready)
			begin
				uart_tx_next_state = UART_TX_START;
			end
			else
			begin
				uart_tx_next_state = UART_TX_IDLE;
			end
		end
		UART_TX_START: begin
			uart_tx_next_state = UART_TX_DATA;
		end
		UART_TX_DATA: begin
			if(data_tx_done)
			begin	
				if(parity_en)
					uart_tx_next_state = UART_TX_PARITY;
				else
					uart_tx_next_state = UART_TX_STOP;
			end
			else
				uart_tx_next_state = UART_TX_DATA;
		end
		UART_TX_PARITY: begin
				uart_tx_next_state = UART_TX_STOP;
		end
		UART_TX_STOP: begin
				uart_tx_next_state = UART_TX_IDLE;
		end
		default: begin
				uart_tx_next_state = UART_TX_IDLE;
		end
		endcase
	end
	else
	begin
		uart_tx_next_state = uart_tx_state;
	end
end

//tx_data_bit_cnt
always @ (posedge PCLK or negedge PRESETN)
begin
	if(!PRESETN)
	begin
		tx_data_bit_cnt <= 3'h0;
	end
	else
	begin
		if(uart_tx_state == UART_TX_DATA)
		begin
			if(tx_baud_pulse)
			begin
				if(data_tx_done)
				tx_data_bit_cnt <= 3'h0;
				else
				tx_data_bit_cnt <= tx_data_bit_cnt + 3'h1;
			end
		end
		else
		begin
			tx_data_bit_cnt <= 3'h0;
		end
	end
end

//TX
always @ (posedge PCLK or negedge PRESETN)
begin
	if(!PRESETN)
	begin
		UART_TX <= 1'b1;
	end
	else
	begin
		case (uart_tx_state)
		UART_TX_IDLE: begin
			UART_TX <= 1'b1;	
		end
		UART_TX_START: begin
			UART_TX <= 1'b0;
		end
		UART_TX_DATA: begin
			UART_TX <= uart_tx_buf_rd_data[tx_data_bit_cnt];
		end
		UART_TX_PARITY: begin
			if(parity_odd0_even1)
			UART_TX <= ^(uart_tx_buf_rd_data);
			else 
			UART_TX <= ~^(uart_tx_buf_rd_data);
		end
		UART_TX_STOP: begin
			UART_TX <= 1'b1;
		end
		default: begin
			UART_TX <= 1'b1;
		end
		endcase
	end
end


assign tx_ready = !uart_tx_buf_full;

endmodule
