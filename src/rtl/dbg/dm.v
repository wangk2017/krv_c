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
// File Name: 		dm.v					||
// Author:    		Kitty Wang				||
// Description: 						||
//	      		Debug Module                            ||
// History:   		2019.05.12				||
//                      First version				||
//===============================================================
`include "core_defines.vh"
`include "dbg_defines.vh"

module dm(
//global signals
input				sys_clk,
input				sys_rstn,

//DTM interface
input				dtm_req_valid,
output				dtm_req_ready,
input[`DBUS_M_WIDTH - 1 : 0]	dtm_req_bits,

output				dm_resp_valid,
input				dm_resp_ready,
output[`DBUS_S_WIDTH - 1 : 0]	dm_resp_bits,

//core interface

output				dbg_reg_access,
output 				dbg_wr1_rd0,
output[`CMD_REGNO_SIZE - 1 : 0]	dbg_regno,
output [`DATA_WIDTH - 1 : 0]	dbg_write_data,
input 				dbg_read_data_valid,
input [`DATA_WIDTH - 1 : 0]	dbg_read_data

);


//wires declaration
wire [`DM_REG_WIDTH - 1 : 0]	command;
wire [`DM_REG_WIDTH - 1 : 0]	data0;
wire 				cmd_update;
wire				cmd_finished;
wire [`DATA_WIDTH - 1 : 0]	cmd_read_data;

//sub-modules
dm_regs u_dm_regs (
.sys_clk		(sys_clk	),
.sys_rstn		(sys_rstn	),
.data0			(data0	),
.command		(command	),
.cmd_update		(cmd_update	),
.cmd_finished		(cmd_finished		),
.cmd_read_data		(cmd_read_data		),
.dtm_req_valid		(dtm_req_valid	),
.dtm_req_ready		(dtm_req_ready	),
.dtm_req_bits		(dtm_req_bits	),
.dm_resp_valid		(dm_resp_valid	),
.dm_resp_ready		(dm_resp_ready	),
.dm_resp_bits		(dm_resp_bits	)
);

//abs_cmd
abs_cmd u_abs_cmd(
.sys_clk		(sys_clk		),
.sys_rstn		(sys_rstn		),
.data0			(data0	),
.command		(command		),
.cmd_update		(cmd_update		),
.cmd_finished		(cmd_finished		),
.cmd_read_data		(cmd_read_data		),
.valid_reg_access	(dbg_reg_access		),
.wr1_rd0		(dbg_wr1_rd0		),
.regno			(dbg_regno		),
.write_data		(dbg_write_data		),
.read_data_valid	(dbg_read_data_valid	),
.read_data		(dbg_read_data		)
);


endmodule
