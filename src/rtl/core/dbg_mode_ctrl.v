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
output reg dbg_mode
);


assign single_step = step && resumereq_w1;

always @ (posedge cpu_clk or negedge cpu_rstn)
begin
	if(!cpu_rstn)
	begin
		single_step_d1 <= 1'b0;
		single_step_d2 <= 1'b0;
	end
	else
	begin
		single_step_d1 <= single_step;
		single_step_d2 <= single_step_d1;
	end
end

always @ (posedge cpu_clk or negedge cpu_rstn)
begin
	if(!cpu_rstn)
	dbg_mode <= 1'b0;
	else 
	begin
		if (dret || resumereq_w1)
		dbg_mode <= 1'b0;
		else if(ebreak || breakpoint || single_step_d1)
		dbg_mode <= 1'b1;
	end
end

endmodule
