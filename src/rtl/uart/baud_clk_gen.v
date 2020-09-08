//==============================================================||
// File Name: 		baud_clk_gen.v				||
// Author:    		Kitty Wang				||
// Description: 						||
//	      		UART baud clock generation 		||
// History:   		2019.04.26				||
//                      First version				||
//===============================================================

module baud_clk_gen (
input        	PCLK,
input        	PRESETN,
input [12:0] 	baud_val,
output 		tx_baud_pulse,
output 		rx_sample_pulse
);

reg [12:0] baud_cnt;

always @ (posedge PCLK or negedge PRESETN)
begin
	if(!PRESETN)
	begin
		baud_cnt <= 13'h0;
	end
	else
	begin
		if(rx_sample_pulse)
		begin
			baud_cnt <= 13'h0;	
		end
		else
		begin
			baud_cnt <= baud_cnt + 13'h1;
		end
	end
end

assign rx_sample_pulse = (baud_cnt == baud_val);

reg[3:0] tx_cnt;
wire tx_pulse_en = tx_cnt == 4'hf;
always @ (posedge PCLK or negedge PRESETN)
begin
	if(!PRESETN)
	begin
		tx_cnt <= 4'h0;
	end
	else
	begin
		if(rx_sample_pulse)
		begin
			if(tx_pulse_en)
			begin
				tx_cnt <= 4'h0;
			end
			else
			begin
				tx_cnt <= tx_cnt + 4'h1;
			end
		end
	end
end

assign tx_baud_pulse = tx_pulse_en && rx_sample_pulse;

endmodule 
