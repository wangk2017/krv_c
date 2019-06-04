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
// File Name: 		dm_regs.v				||
// Author:    		Kitty Wang				||
// Description: 						||
//	      		Debug Module Registers                  ||
// History:   		2019.05.21				||
//                      First version				||
//===============================================================
`include "core_defines.vh"
`include "dbg_defines.vh"

module dm_regs(
//global signals
input				sys_clk,
input				sys_rstn,

//DM internal sub-module interface
output reg [`DM_REG_WIDTH - 1 : 0]	data0,
output reg [`DM_REG_WIDTH - 1 : 0]	command,
output reg 				cmd_update,
input 					cmd_finished,
input [`DATA_WIDTH - 1 : 0]		cmd_read_data,

//DTM interface
input				dtm_req_valid,
output				dtm_req_ready,
input[`DBUS_M_WIDTH - 1 : 0]	dtm_req_bits,

output				dm_resp_valid,
input				dm_resp_ready,
output[`DBUS_S_WIDTH - 1 : 0]	dm_resp_bits

);

wire [`DBUS_M_WIDTH - 1 : 0]		valid_dtm_req = dtm_req_valid ? dtm_req_bits : {`DBUS_M_WIDTH{1'b0}};

wire [`DBUS_OP_WIDTH - 1 : 0] 		dm_access_op = valid_dtm_req[`DBUS_OP_WIDTH - 1 : 0];
wire [`DBUS_ADDR_WIDTH - 1 : 0] 	dm_access_addr = valid_dtm_req[(`DBUS_OP_WIDTH + `DBUS_DATA_WIDTH - 1) : `DBUS_OP_WIDTH];
wire [`DBUS_DATA_WIDTH - 1 : 0] 	dm_access_data = valid_dtm_req [`DBUS_M_WIDTH -1 : (`DBUS_OP_WIDTH + `DBUS_ADDR_WIDTH)];

wire dm_reg_wr = dm_access_op[1] && !dm_access_op[0];
wire dm_reg_rd = !dm_access_op[1] && dm_access_op[0];


//addr decoder
wire dmstatus_sel 	= (dm_access_addr == `DMSTATUS_ADDR	);
wire dmcontrol_sel 	= (dm_access_addr == `DMCONTROL_ADDR	);
wire hartinfo_sel 	= (dm_access_addr == `HARTINFO_ADDR	);
wire abstractcs_sel 	= (dm_access_addr == `ABSTRACTCS_ADDR	);
wire command_sel 	= (dm_access_addr == `COMMAND_ADDR	);
wire data0_sel 		= (dm_access_addr == `DATA0_ADDR	);
wire sbcs_sel 		= (dm_access_addr == `SBCS_ADDR	);
wire sbaddr0_sel 	= (dm_access_addr == `SBADDR0_ADDR	);
wire sbdata0_sel 	= (dm_access_addr == `SBDATA0_ADDR	);


//TO DO
//dmstatus
//0x11 RO
//22: impebreak
//19: allhavereset
//18  anyhavereset

//data0
always @ (posedge sys_clk or negedge sys_rstn)
begin
	if (!sys_rstn)
	begin
		data0 <= {`DM_REG_WIDTH{1'b1}};
	end
	else
	begin
		if (data0_sel && dm_reg_wr)
		begin
			data0 <= dm_access_data;
		end
		else
		begin
			data0 <= data0;
		end
	end
end
wire [`DM_REG_WIDTH - 1 : 0] data0_read_data;
assign data0_read_data = data0_sel ? data0 : {`DM_REG_WIDTH{1'b0}};



//command

always @ (posedge sys_clk or negedge sys_rstn)
begin
	if (!sys_rstn)
	begin
		command <= {`DM_REG_WIDTH{1'b1}};
		cmd_update <= 1'b0;
	end
	else
	begin
		if (command_sel && dm_reg_wr)
		begin
			command <= dm_access_data;
			cmd_update <= 1'b1;
		end
		else
		begin
			command <= command;
			cmd_update <= 1'b0;
		end
	end
end
wire [`DM_REG_WIDTH - 1 : 0] command_read_data;
assign command_read_data = command_sel ? command : {`DM_REG_WIDTH{1'b0}};

//dm regs read
wire dm_regs_read_data = {`DATA_WIDTH{dm_reg_rd}} &
				(data0_read_data |
				 command_read_data
				);

//handshake with dtm
reg cmd_outstanding;
always @ (posedge sys_clk or negedge sys_rstn)
begin
	if (!sys_rstn)
	begin
		cmd_outstanding <= 1'b0;
	end
	else 
	begin
		if(cmd_finished)
		cmd_outstanding <= 1'b0;
		else if(command_sel && dm_reg_wr)
		cmd_outstanding <= 1'b1;
	end
end

assign dtm_req_ready = !cmd_outstanding;

assign dm_resp_valid = cmd_finished || dm_reg_rd;
assign dm_resp_bits = {dm_access_op,dm_regs_read_data | cmd_read_data};


endmodule
