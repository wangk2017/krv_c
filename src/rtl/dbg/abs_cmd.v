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
// File Name: 		abs_cmd.v				||
// Author:    		Kitty Wang				||
// Description: 						||
//	      		Abstract Command Module                 ||
// History:   		2019.05.23				||
//                      First version				||
//===============================================================
`include "core_defines.vh"
`include "dbg_defines.vh"

module abs_cmd(

//global signal
input				sys_clk,
input				sys_rstn,

//from dm_regs
input [`DM_REG_WIDTH - 1 : 0]	data0,
input [`DM_REG_WIDTH - 1 : 0]	command,
input 				cmd_update,
output				cmd_finished,
output [`DATA_WIDTH - 1 : 0]	cmd_read_data,

//to CSRs
output				valid_reg_access,
output 				wr1_rd0,
output[`CMD_REGNO_SIZE - 1 : 0]	regno,
output [`DATA_WIDTH - 1 : 0]	write_data,
input				read_data_valid,
input [`DATA_WIDTH - 1 : 0]	read_data

);

//abstract the command field
wire [`CMD_CMDTYPE_SIZE - 1 : 0] 	cmdtype  = command [`CMD_CMDTYPE_RANGE ];
wire [`CMD_TRANSFER_SIZE - 1 : 0] 	transfer = command [`CMD_TRANSFER_RANGE];	

assign valid_reg_access = (cmdtype == `ACCESS_REG_CMD) && transfer && cmd_update;
assign 	wr1_rd0  = command [`CMD_WRITE_RANGE   ];  	
assign  regno    = command [`CMD_REGNO_RANGE   ];  	

assign write_data = data0;
assign cmd_read_data = read_data;
assign cmd_finished = read_data_valid || (wr1_rd0 && valid_reg_access);

endmodule
