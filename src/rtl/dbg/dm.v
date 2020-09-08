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
//system_bus_access IF
input wire HCLK,
input wire HRESETn,
input wire HGRANT,
input wire HREADY,
input wire [1:0] HRESP,
input wire [`AHB_DATA_WIDTH - 1 : 0] HRDATA,
output wire HBUSREQ,
output wire HLOCK,
output wire [1:0] HTRANS,
output wire [`AHB_ADDR_WIDTH - 1 : 0] HADDR,
output wire HWRITE,
output wire [2:0] HSIZE,
output wire [2:0] HBURST,
output wire [3:0] HPROT,
output wire [`AHB_DATA_WIDTH - 1 : 0] HWDATA,


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
output				resumereq_w1,
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

wire [`DM_REG_WIDTH - 1 : 0]	sbaddress0;
wire        			sbaddress0_update;
wire [`DM_REG_WIDTH - 1 : 0]	sbdata0;
wire        			sbdata0_update;
wire        			sbdata0_rd;
wire [`DM_REG_WIDTH - 1 : 0]	system_bus_read_data;
wire 				system_bus_read_data_valid;
wire 				sbbusy;
wire        			sbreadonaddr;
wire [2:0]			sbaccess;
wire        			sbreadondata;
wire [2:0]			sberror;
wire [2:0]			sberror_w1;
wire  				sbbusyerror;
wire				sbbusyerror_w1;


//sub-modules
dm_regs u_dm_regs (
.sys_clk		(sys_clk	),
.sys_rstn		(sys_rstn	),
.resumereq_w1		(resumereq_w1	),
.data0			(data0		),
.command		(command	),
.cmd_update		(cmd_update	),
.cmd_finished		(cmd_finished		),
.sbaddress0		(sbaddress0		),
.sbaddress0_update	(sbaddress0_update	),
.sbdata0		(sbdata0		),
.sbdata0_update		(sbdata0_update		),
.sbdata0_rd		(sbdata0_rd		),
.system_bus_read_data	(system_bus_read_data	),
.system_bus_read_data_valid	(system_bus_read_data_valid	),
.sbbusy			(sbbusy			),
.sbreadonaddr		(sbreadonaddr		),
.sbaccess		(sbaccess		),
.sbreadondata		(sbreadondata		),
.sberror		(sberror		),
.sberror_w1		(sberror_w1		),
.sbbusyerror		(sbbusyerror		),
.sbbusyerror_w1		(sbbusyerror_w1		),
.cmd_read_data_valid	(dbg_read_data_valid	),
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

//system_bus_access

system_bus_access u_system_bus_access (
	.HCLK		(HCLK),
	.HRESETn	(HRESETn),
	.HBUSREQ	(HBUSREQ),
	.HGRANT		(HGRANT),
	.HREADY		(HREADY),
	.HRESP		(HRESP),
	.HRDATA		(HRDATA),
	.HLOCK		(HLOCK),
	.HTRANS		(HTRANS),
	.HADDR		(HADDR),
	.HWRITE		(HWRITE),
	.HSIZE		(HSIZE),
	.HBURST		(HBURST),
	.HPROT		(HPROT),
	.HWDATA		(HWDATA),
.sys_clk		(sys_clk		),
.sys_rstn		(sys_rstn		),
.sbaddress0		(sbaddress0		),
.sbaddress0_update	(sbaddress0_update	),
.sbdata0		(sbdata0		),
.sbdata0_update		(sbdata0_update		),
.sbdata0_rd		(sbdata0_rd		),
.system_bus_read_data	(system_bus_read_data	),
.system_bus_read_data_valid	(system_bus_read_data_valid	),
.sbbusy			(sbbusy			),
.sbreadonaddr		(sbreadonaddr		),
.sbaccess		(sbaccess		),
.sbreadondata		(sbreadondata		),
.sberror		(sberror		),
.sberror_w1		(sberror_w1		),
.sbbusyerror		(sbbusyerror		),
.sbbusyerror_w1		(sbbusyerror_w1		)

);

endmodule
