
//==============================================================||
// File Name: 		div_u.v					||
// Author:    		Kitty Wang				||
// Description: 						||
//	      		unsigned divider block               	|| 
// History:   							||
//                      First version				||
//===============================================================
`include "core_defines.vh"

module div_u (

input wire cpu_clk,				//cpu clock
input wire cpu_rstn,				//cpu clock

input wire start,				//start divider
output wire done,				//divider done 

input wire [`DATA_WIDTH - 1 : 0] div_src_data1,	//source data1 for divider
input wire [`DATA_WIDTH - 1 : 0] div_src_data2,	//source data2 for divider

output wire [`DATA_WIDTH - 1 : 0] rem_result,	//rem result output
output wire [`DATA_WIDTH - 1 : 0] div_result	//divider result output
);

/*
assign div_result = div_src_data1 / div_src_data2;
assign rem_result = div_src_data1 % div_src_data2;
*/
parameter D_DATA_WIDTH = `DATA_WIDTH * 2;
reg [D_DATA_WIDTH - 1 : 0] hold_r;

wire data1ltdata2 = div_src_data1 < div_src_data2;
wire data2equ1 = (div_src_data2 == 1);
wire data2equ0 = (div_src_data2 == 0);

wire single_cycle_div =  data1ltdata2 | data2equ1 | data2equ0;

reg start_r;
always @ (posedge cpu_clk or negedge cpu_rstn)
begin
	if(!cpu_rstn)
	begin
		start_r <= 1'b0;
	end
	else
	begin
		start_r <= start;
	end
end
assign start_rising = start && !start_r;

reg [5:0] div_cycle_cnt;

always @ (posedge cpu_clk or negedge cpu_rstn)
begin
	if(!cpu_rstn)
	begin
		div_cycle_cnt <= 5'h0;
	end
	begin
		if(start_rising && (!single_cycle_div))
		begin
			div_cycle_cnt <= 5'h0;
		end
		else if(start)
		begin
			if(div_cycle_cnt == `DATA_WIDTH)
			begin
				div_cycle_cnt <= 5'h0;
			end
			else
			begin
				div_cycle_cnt <= div_cycle_cnt + 5'h1;
			end
		end
		else
		begin
			div_cycle_cnt <= 5'h0;
		end
	end
end

always @ (posedge cpu_clk or negedge cpu_rstn)
begin
	if(!cpu_rstn)
	begin
		hold_r <= {D_DATA_WIDTH{1'b0}};
	end
	else 
	begin
		if(start_rising && (!single_cycle_div))
		begin
			hold_r[`DATA_WIDTH : 1] <= div_src_data1[`DATA_WIDTH - 1 : 0];
		end
		else if(start)
		begin
			if(div_cycle_cnt < 32)
			begin
				if(hold_r[D_DATA_WIDTH - 1 : `DATA_WIDTH] >= div_src_data2)	
				begin	
					hold_r[0] <= 1'b1;
					hold_r[D_DATA_WIDTH - 1 : `DATA_WIDTH + 1] <= hold_r[D_DATA_WIDTH - 1 : `DATA_WIDTH] - div_src_data2 ;
					hold_r[`DATA_WIDTH : 1] <= hold_r[`DATA_WIDTH - 1 : 0];
				end
				else
				begin
					hold_r[0] <= 1'b0;
					hold_r[D_DATA_WIDTH - 1 : 1] <= hold_r[D_DATA_WIDTH - 2 : 0];
				end
			end
		end
		else 
		begin
			hold_r <= 0;
		end
	end
end

assign done = single_cycle_div | (div_cycle_cnt == `DATA_WIDTH);

assign div_result = data2equ0 ? {`DATA_WIDTH{1'b1}} : (data2equ1 ? div_src_data1 :  (data1ltdata2 ? {`DATA_WIDTH{1'b0}} : (done ? hold_r[`DATA_WIDTH - 1 : 0] : {`DATA_WIDTH{1'b0}})));
assign rem_result = data2equ1 ? {`DATA_WIDTH{1'b0}} : ((data1ltdata2 | data2equ0) ? div_src_data1 : (done ? {1'b0,hold_r[D_DATA_WIDTH - 1 : `DATA_WIDTH + 1]} : {`DATA_WIDTH{1'b0}}));

endmodule
