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

output					resumereq_w1,
//interface with abs_cmd block
output reg [`DM_REG_WIDTH - 1 : 0]	data0,
output reg [`DM_REG_WIDTH - 1 : 0]	command,
output reg 				cmd_update,
input 					cmd_finished,
input 					cmd_read_data_valid,
input [`DATA_WIDTH - 1 : 0]		cmd_read_data,

//interface with system_bus_access block
output reg [`DM_REG_WIDTH - 1 : 0]	sbaddress0,
output reg				sbaddress0_update,
output reg [`DM_REG_WIDTH - 1 : 0]	sbdata0,
output reg				sbdata0_update,
output reg				sbdata0_rd,
input [`DM_REG_WIDTH - 1 : 0]		system_bus_read_data,
input 					system_bus_read_data_valid,
input					sbbusy,
output reg				sbreadonaddr,
output reg[2:0]				sbaccess,
output reg				sbreadondata,
input [2:0]				sberror,
output reg[2:0]				sberror_w1,
input 					sbbusyerror,
output reg				sbbusyerror_w1,

//DTM interface
input				dtm_req_valid,
output				dtm_req_ready,
input[`DBUS_M_WIDTH - 1 : 0]	dtm_req_bits,

output reg			dm_resp_valid,
input				dm_resp_ready,
output reg[`DBUS_S_WIDTH - 1 : 0]	dm_resp_bits

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
wire sbaddress0_sel 	= (dm_access_addr == `SBADDR0_ADDR	);
wire sbdata0_sel 	= (dm_access_addr == `SBDATA0_ADDR	);


//TO DO
//dmstatus
//0x11 RO
//22: impebreak
//19: allhavereset
//18  anyhavereset
//dmcontrol
reg haltreq;
always @ (posedge sys_clk or negedge sys_rstn)
begin
	if (!sys_rstn)
	begin
		haltreq <= 1'b0;
	end
	else
	begin
		if (dmcontrol_sel && dm_reg_wr)
		begin
			haltreq <= dm_access_data[31];
		end
	end
end

assign resumereq_w1 = (!haltreq) && (dmcontrol_sel && dm_reg_wr && dm_access_data[30]);

//data0
always @ (posedge sys_clk or negedge sys_rstn)
begin
	if (!sys_rstn)
	begin
		data0 <= {`DM_REG_WIDTH{1'b0}};
	end
	else
	begin
		if (data0_sel && dm_reg_wr)
		begin
			data0 <= dm_access_data;
		end
		else if(cmd_read_data_valid)
		begin
			data0 <= cmd_read_data;
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
		command <= {`DM_REG_WIDTH{1'b0}};
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

//system_bus_access
//sbcs @0x38
always @ (posedge sys_clk or negedge sys_rstn)
begin
	if (!sys_rstn)
	begin
		sbreadonaddr <= 1'b0;
		sbaccess <= 3'h0;
		sbreadondata <= 1'b0;
	end
	else
	begin
		if (sbcs_sel && dm_reg_wr)
		begin
			sbreadonaddr <= dm_access_data[20];
			sbaccess <= dm_access_data[19:17];
			sbreadondata <= dm_access_data[15];
		end
	end
end

always @ (posedge sys_clk or negedge sys_rstn)
begin
	if (!sys_rstn)
	begin
		sbbusyerror_w1 <= 1'b0;
	end
	else
	begin
		if (sbcs_sel && dm_reg_wr)
		begin
			sbbusyerror_w1 <= dm_access_data[22];
		end
		else
		begin
			sbbusyerror_w1 <= 1'b0;
		end
	end
end

always @ (posedge sys_clk or negedge sys_rstn)
begin
	if (!sys_rstn)
	begin
		sberror_w1 <= 3'h0;
	end
	else
	begin
		if (sbcs_sel && dm_reg_wr)
		begin
			sberror_w1 <= dm_access_data[14:12];
		end
		else
		begin
			sberror_w1 <= 3'h0;
		end
	end
end

wire [2:0] sbversion = 3'h1;
wire sbautoincrement = 1'b0;		//currently auto-increment is not supported
wire [6:0] sbasize = 6'h20;		//current system bus address is 32b
//32b/16b/8b access support
wire sbaccess128 = 1'b0;
wire sbaccess64 = 1'b0;
wire sbaccess32 = 1'b1;
wire sbaccess16 = 1'b1;
wire sbaccess8 = 1'b1;

wire [`DM_REG_WIDTH - 1 : 0] sbcs_read_data;
assign sbcs_read_data = sbcs_sel ?{sbversion,6'h0,sbbusyerror,sbbusy,sbreadonaddr,sbaccess,sbautoincrement,sbreadondata,sberror,sbasize,sbaccess128,sbaccess64,sbaccess32,sbaccess16,sbaccess8}  : {`DM_REG_WIDTH{1'b0}};

//sbaddress0 @0x39
always @ (posedge sys_clk or negedge sys_rstn)
begin
	if (!sys_rstn)
	begin
		sbaddress0 <= {`DM_REG_WIDTH{1'b0}};
		sbaddress0_update <= 1'b0;
	end
	else
	begin
		if (sbaddress0_sel && dm_reg_wr)
		begin
			sbaddress0 <= dm_access_data;
			sbaddress0_update <= 1'b1;
		end
		else
		begin
			sbaddress0 <= sbaddress0;
			sbaddress0_update <= 1'b0;
		end
	end
end
wire [`DM_REG_WIDTH - 1 : 0] sbaddress0_read_data;
assign sbaddress0_read_data = sbaddress0_sel ? sbaddress0 : {`DM_REG_WIDTH{1'b0}};

//sbdata0 @0x3c
always @ (posedge sys_clk or negedge sys_rstn)
begin
	if (!sys_rstn)
	begin
		sbdata0 <= {`DM_REG_WIDTH{1'b0}};
		sbdata0_update <= 1'b0;
	end
	else
	begin
		if (sbdata0_sel && dm_reg_wr)
		begin
			sbdata0 <= dm_access_data;
			sbdata0_update <= 1'b1;
		end
		else if(system_bus_read_data_valid)
		begin
			sbdata0 <= system_bus_read_data;
			sbdata0_update <= 1'b0;
		end
		else
		begin
			sbdata0_update <= 1'b0;
		end
	end
end
wire [`DM_REG_WIDTH - 1 : 0] sbdata0_read_data;
assign sbdata0_read_data = sbdata0_sel ? sbdata0 : {`DM_REG_WIDTH{1'b0}};

always @ (posedge sys_clk or negedge sys_rstn)
begin
	if (!sys_rstn)
	begin
		sbdata0_rd <= 1'b0;
	end
	else
	begin
		if (sbdata0_sel && dm_reg_rd && sbreadondata)
		begin
			sbdata0_rd <= 1'b1;
		end
		else
		begin
			sbdata0_rd <= 1'b0;
		end
	end
end



//dm regs read
wire [`DM_REG_WIDTH - 1 : 0] dm_regs_read_data = {`DATA_WIDTH{dm_reg_rd}} &
				(data0_read_data |
				 command_read_data |
				 sbaddress0_read_data |
				 sbdata0_read_data |
				 sbcs_read_data 
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

reg sb_read_outstanding;
always @ (posedge sys_clk or negedge sys_rstn)
begin
	if (!sys_rstn)
	begin
		sb_read_outstanding <= 1'b0;
	end
	else 
	begin
		if(system_bus_read_data_valid)
		sb_read_outstanding <= 1'b0;
		else if(sbdata0_rd)
		sb_read_outstanding <= 1'b1;
	end
end

assign dtm_req_ready = !(cmd_outstanding || sb_read_outstanding || sbbusy || sbbusyerror || (|sberror));

always @ (posedge sys_clk or negedge sys_rstn)
begin
	if (!sys_rstn)
	begin
		dm_resp_valid <= 1'b0;
		dm_resp_bits <= 0;
	end
	else
	begin
		if(dm_resp_ready)
		begin
			dm_resp_valid <= (dm_reg_rd && !sb_read_outstanding);
			dm_resp_bits <= {dm_access_op,dm_regs_read_data};
		end
		else if(dm_reg_rd)
		begin
			dm_resp_valid <= 1'b1;
			dm_resp_bits <= {dm_access_op,dm_regs_read_data};
		end
	end
end

endmodule
