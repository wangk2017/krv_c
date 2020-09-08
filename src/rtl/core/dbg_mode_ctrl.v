
//==============================================================||
// File Name: 		dbg_mode_ctrl.v				||
// Author:    		Kitty Wang				||
// Description: 						||
//	      		core debug mode control module          ||
// History:   							||
//                      2019/5/29 				||
//                      First version				||
//===============================================================


`include "core_defines.vh"
`include "dbg_defines.vh"

module dbg_mode_ctrl (

input cpu_clk,
input cpu_rstn,

input step,
input resumereq_w1,
input breakpoint,
input ebreak,
input dret,
output single_step,
output reg single_step_d1,
output reg single_step_d2,
output reg single_step_d3,
output reg single_step_d4,
output reg dbg_mode
);


assign single_step = step && resumereq_w1;

always @ (posedge cpu_clk or negedge cpu_rstn)
begin
	if(!cpu_rstn)
	begin
		single_step_d1 <= 1'b0;
		single_step_d2 <= 1'b0;
		single_step_d3 <= 1'b0;
		single_step_d4 <= 1'b0;
	end
	else
	begin
		single_step_d1 <= single_step;
		single_step_d2 <= single_step_d1;
		single_step_d3 <= single_step_d2;
		single_step_d4 <= single_step_d3;
	end
end

always @ (posedge cpu_clk or negedge cpu_rstn)
begin
	if(!cpu_rstn)
	dbg_mode <= 1'b0;
	else 
	begin
		if (dret || (resumereq_w1 && !step))
		dbg_mode <= 1'b0;
		else if(ebreak || breakpoint)
		dbg_mode <= 1'b1;
	end
end

endmodule
