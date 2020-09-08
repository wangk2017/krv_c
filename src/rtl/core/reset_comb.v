
//==============================================================||
// File Name: 		reset_comb.v				||
// Author:    		Kitty Wang				||
// Description: 						||
//	      		reset combine block               	|| 
// History:   							||
//                      2017/9/26 				||
//                      First version				||
//===============================================================

module reset_comb (
input wire cpu_rstn,				//cpu reset, active low
input wire pg_resetn,				//power gating reset, active low
output wire comb_rstn				//combined reset,active low

);



assign comb_rstn = cpu_rstn && pg_resetn;

endmodule
