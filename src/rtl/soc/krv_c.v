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
// File Name: 		krv_c.v					||
// Author:    		Kitty Wang				||
// Description: 						||
//	      		top of krv-m			     	|| 
// History:   							||
//===============================================================

`include "top_defines.vh"
module krv_c (
//global interface
input clk_in,		//clock in
input porn,		//power on reset, active low

//GPIO 
input [7:0] GPIO_IN,
output [7:0] GPIO_OUT,

//UART
input UART_RX,
output UART_TX

`ifdef KRV_HAS_DBG
,
input				TDI,
output				TDO,
input				TCK,
input				TMS,
input				TRST
`endif

);

//Wires
//PLL
wire cpu_clk;
wire cpu_rstn;
wire HCLK;
wire HRESETn;
wire kplic_clk;
wire kplic_rstn;

wire dma_dtcm_access = 1'b0;			
wire dma_dtcm_ready;
wire dma_dtcm_rd0_wr1 = 1'b0;
wire [`ADDR_WIDTH - 1 : 0] dma_dtcm_addr = 32'h0;
wire [`DATA_WIDTH - 1 : 0] dma_dtcm_wdata = 32'h0;
wire [`DATA_WIDTH - 1 : 0] dma_dtcm_rdata;
wire dma_dtcm_rdata_valid;	

	wire cpu_clk_g;
	wire kplic_int;
	wire core_timer_int;
	wire DAHB_HGRANT;
	wire DAHB_HREADY;
	wire [1:0] DAHB_HRESP;
	wire [`AHB_DATA_WIDTH - 1 : 0] DAHB_HRDATA;
	wire DAHB_HBUSREQ;
	wire DAHB_HLOCK;
	wire [1:0] DAHB_HTRANS;
	wire [`AHB_ADDR_WIDTH - 1 : 0] DAHB_HADDR;
	wire DAHB_HWRITE;
	wire [2:0] DAHB_HSIZE;
	wire [2:0] DAHB_HBURST;
	wire [3:0] DAHB_HPROT;
	wire [`AHB_DATA_WIDTH - 1 : 0] DAHB_HWDATA;
	wire DAHB_access;	
	wire DAHB_rd0_wr1;		
	wire [2:0] DAHB_size;
	wire [`DATA_WIDTH - 1 : 0] DAHB_write_data;
	wire [`ADDR_WIDTH - 1 : 0] DAHB_addr;
	wire DAHB_trans_buffer_full;
	wire [`DATA_WIDTH - 1 : 0] DAHB_read_data;
	wire DAHB_read_data_valid;

	wire instr_itcm_access;
	wire [`ADDR_WIDTH - 1 : 0] instr_itcm_addr;
	wire [`DATA_WIDTH - 1 : 0] instr_itcm_read_data;
	wire instr_itcm_read_data_valid;

	wire instr_dtcm_access;
	wire [`ADDR_WIDTH - 1 : 0] instr_dtcm_addr;
	wire [`DATA_WIDTH - 1 : 0] instr_dtcm_read_data;
	wire instr_dtcm_read_data_valid;

	wire IAHB_ready;
	wire itcm_auto_load;
	wire [`ADDR_WIDTH - 1 : 0 ] itcm_auto_load_addr;

	wire data_itcm_access;
	wire data_itcm_ready;
	wire data_itcm_rd0_wr1;	
	wire [3:0] data_itcm_byte_strobe;
	wire [`DATA_WIDTH - 1 : 0] data_itcm_write_data;
	wire [`ADDR_WIDTH - 1 : 0] data_itcm_addr;
	wire [`DATA_WIDTH - 1 : 0] data_itcm_read_data;
	wire data_itcm_read_data_valid;
	  
	wire data_dtcm_access;
	wire data_dtcm_ready;
	wire data_dtcm_rd0_wr1;	
	wire [3:0] data_dtcm_byte_strobe;
	wire [`DATA_WIDTH - 1 : 0]  data_dtcm_write_data;
	wire [`ADDR_WIDTH - 1 : 0] data_dtcm_addr;
	wire [`DATA_WIDTH - 1 : 0] data_dtcm_read_data;
	wire data_dtcm_read_data_valid;
	  
	wire IAHB_HGRANT;
	wire IAHB_HBUSREQ;
	wire IAHB_HLOCK;
	wire IAHB_HREADY;
	wire [1:0] IAHB_HRESP;
	wire [`AHB_DATA_WIDTH - 1 : 0] IAHB_HRDATA;
	wire [1:0] IAHB_HTRANS;
	wire [`AHB_ADDR_WIDTH - 1 : 0] IAHB_HADDR;
	wire IAHB_HWRITE;
	wire IAHB_access;	
	wire [`ADDR_WIDTH - 1 : 0] IAHB_addr;
	wire [`DATA_WIDTH - 1 : 0] IAHB_read_data;
	wire IAHB_read_data_valid;

	 wire HSEL_kplic;
	 wire [`AHB_ADDR_WIDTH - 1 : 0] HADDR_kplic;
	 wire HWRITE_kplic;
	 wire [1:0] HTRANS_kplic;
	 wire [2:0] HBURST_kplic;
	 wire [`AHB_DATA_WIDTH - 1 : 0] HWDATA_kplic;
	 wire HREADY_kplic;
	 wire [1:0] HRESP_kplic;
	 wire [`AHB_DATA_WIDTH - 1 : 0] HRDATA_kplic;

	 wire HSEL_core_timer;
	 wire [`AHB_ADDR_WIDTH - 1 : 0] HADDR_core_timer;
	 wire HWRITE_core_timer;
	 wire [1:0] HTRANS_core_timer;
	 wire [2:0] HBURST_core_timer;
	 wire [`AHB_DATA_WIDTH - 1 : 0] HWDATA_core_timer;
	 wire HREADY_core_timer;
	 wire [1:0] HRESP_core_timer;
	 wire [`AHB_DATA_WIDTH - 1 : 0] HRDATA_core_timer;


	 wire HSEL_apb;
	 wire [`AHB_ADDR_WIDTH - 1 : 0] HADDR_apb;
	 wire HWRITE_apb;
	 wire [1:0] HTRANS_apb;
	 wire [2:0] HBURST_apb;
	 wire [`AHB_DATA_WIDTH - 1 : 0] HWDATA_apb;
	 wire HREADY_apb;
	 wire [1:0] HRESP_apb;
	 wire [`AHB_DATA_WIDTH - 1 : 0] HRDATA_apb;


	 wire HSEL_S0;
	 wire HSEL_flash;
	 wire [`AHB_ADDR_WIDTH - 1 : 0] HADDR_flash;
	 wire [2 : 0] HSIZE_flash;
	 wire HWRITE_flash;
	 wire [1:0] HTRANS_flash;
	 wire [2:0] HBURST_flash;
	 wire [`AHB_DATA_WIDTH - 1 : 0] HWDATA_flash;
	 wire HREADY_S0;
	 wire HREADY_flash;
	 wire [1:0] HRESP_flash;
	 wire [`AHB_DATA_WIDTH - 1 : 0] HRDATA_flash;
	 wire [`AHB_DATA_WIDTH - 1 : 0] HRDATA_S0;


	wire wfi;
	wire mother_sleep;
	wire daughter_sleep;
	wire isolation_on;
	wire pg_resetn;
	wire save;
	wire restore;

	wire timer_int;

	wire  [`INT_NUM - 1 : 0] external_int = {31'h0, timer_int};

`ifdef KRV_HAS_DBG
wire 				resumereq_w1;
wire				dbg_reg_access;
wire 				dbg_wr1_rd0;
wire[`CMD_REGNO_SIZE - 1 : 0]	dbg_regno;
wire [`DATA_WIDTH - 1 : 0]	dbg_write_data;
wire                     	dbg_read_data_valid;
wire[`DATA_WIDTH - 1 : 0]	dbg_read_data;
	wire sb_HGRANT;
	wire sb_HREADY;
	wire [1:0] sb_HRESP;
	wire [`AHB_DATA_WIDTH - 1 : 0] sb_HRDATA;
	wire sb_HBUSREQ;
	wire sb_HLOCK;
	wire [1:0] sb_HTRANS;
	wire [`AHB_ADDR_WIDTH - 1 : 0] sb_HADDR;
	wire sb_HWRITE;
	wire [2:0] sb_HSIZE;
	wire [2:0] sb_HBURST;
	wire [3:0] sb_HPROT;
	wire [`AHB_DATA_WIDTH - 1 : 0] sb_HWDATA;

`endif
	
//-----------------------------------------------------//
//PLL
//-----------------------------------------------------//
`ifdef ASIC 
/*
//instance of PLL
PLL_nn u_pll (
...
.clk_in		(clk_in),
.clk_out_0	(cpu_clk),
.clk_out_1	(HCLK),
.clk_out_2	(kplic_clk),
)
*/
`else
assign cpu_clk 	= clk_in;
assign HCLK 	= clk_in;
assign kplic_clk 	= clk_in;
`endif

//-----------------------------------------------------//
//Reset sync
//-----------------------------------------------------//
rst_sync u_rst_sync_cpu (
.clk		(cpu_clk),
.in_rstn	(porn),
.out_rstn	(cpu_rstn)
);

rst_sync u_rst_sync_AHB (
.clk		(HCLK),
.in_rstn	(porn),
.out_rstn	(HRESETn)
);

rst_sync u_rst_sync_kplic (
.clk		(kplic_clk),
.in_rstn	(porn),
.out_rstn	(kplic_rstn)
);

//-----------------------------------------------------//
//pg_ctrl
//-----------------------------------------------------//
`ifdef KRV_HAS_PG
pg_ctrl u_pg_ctrl(
	.cpu_clk		(cpu_clk),
	.cpu_rstn		(cpu_rstn),
	.wfi			(wfi),
	.kplic_int		(kplic_int),
	.cpu_clk_g		(cpu_clk_g),
	.mother_sleep		(mother_sleep),
	.daughter_sleep		(daughter_sleep),
	.isolation_on		(isolation_on),
	.pg_resetn		(pg_resetn),
	.save			(save),
	.restore		(restore)
);
`else
assign cpu_clk_g = cpu_clk;
assign pg_resetn = 1'b1;
`endif
	
//-----------------------------------------------------//
//krv core
//-----------------------------------------------------//
core u_core (
	.cpu_clk				(cpu_clk_g),
	.cpu_rstn				(cpu_rstn),
	.pg_resetn				(pg_resetn),
	.boot_addr				(`BOOT_ADDR),
	.kplic_int				(kplic_int),	
	.core_timer_int				(core_timer_int),	
	.wfi					(wfi),

	.instr_itcm_addr			(instr_itcm_addr),
	.instr_itcm_access			(instr_itcm_access),
	.instr_itcm_read_data			(instr_itcm_read_data),
	.instr_itcm_read_data_valid		(instr_itcm_read_data_valid),
	.itcm_auto_load				(itcm_auto_load),
/*
	.data_itcm_rd0_wr1			(data_itcm_rd0_wr1),
	.data_itcm_byte_strobe			(data_itcm_byte_strobe),
	.data_itcm_access			(data_itcm_access),
	.data_itcm_ready			(data_itcm_ready),
	.data_itcm_addr				(data_itcm_addr),
	.data_itcm_write_data			(data_itcm_write_data),
	.data_itcm_read_data			(data_itcm_read_data),
	.data_itcm_read_data_valid		(data_itcm_read_data_valid),
*/

	.instr_dtcm_addr			(instr_dtcm_addr),
	.instr_dtcm_access			(instr_dtcm_access),
	.instr_dtcm_read_data			(instr_dtcm_read_data),
	.instr_dtcm_read_data_valid		(instr_dtcm_read_data_valid),

	.data_dtcm_rd0_wr1			(data_dtcm_rd0_wr1),
	.data_dtcm_byte_strobe			(data_dtcm_byte_strobe),
	.data_dtcm_access			(data_dtcm_access),
	.data_dtcm_ready			(data_dtcm_ready),
	.data_dtcm_addr				(data_dtcm_addr),
	.data_dtcm_write_data			(data_dtcm_write_data),
	.data_dtcm_read_data			(data_dtcm_read_data),
	.data_dtcm_read_data_valid		(data_dtcm_read_data_valid),

	.IAHB_access				(IAHB_access),	
	.IAHB_addr				(IAHB_addr),
	.IAHB_read_data				(IAHB_read_data),
	.IAHB_read_data_valid			(IAHB_read_data_valid),

	.DAHB_access				(DAHB_access),	
	.DAHB_rd0_wr1				(DAHB_rd0_wr1),
	.DAHB_size				(DAHB_size),
	.DAHB_write_data			(DAHB_write_data),
	.DAHB_addr				(DAHB_addr),
	.DAHB_trans_buffer_full			(DAHB_trans_buffer_full),
	.DAHB_read_data				(DAHB_read_data),
	.DAHB_read_data_valid			(DAHB_read_data_valid)
`ifdef KRV_HAS_DBG
//debug interface
,
.resumereq_w1		(resumereq_w1	),
.dbg_reg_access		(dbg_reg_access	),
.dbg_wr1_rd0		(dbg_wr1_rd0	),
.dbg_regno		(dbg_regno	),
.dbg_write_data		(dbg_write_data	),
.dbg_read_data_valid	(dbg_read_data_valid),
.dbg_read_data		(dbg_read_data	)
`endif

);

//-----------------------------------------------------//
//itcm
//-----------------------------------------------------//
wire AHB_itcm_access;
wire AHB_dtcm_access;
wire [`AHB_ADDR_WIDTH - 1 : 0] AHB_tcm_addr;
wire AHB_tcm_rd0_wr1;
wire [3:0] AHB_tcm_byte_strobe;
wire [`KPLIC_DATA_WIDTH - 1 : 0] AHB_tcm_write_data;
wire [`KPLIC_DATA_WIDTH - 1 : 0] AHB_itcm_read_data;
wire [`KPLIC_DATA_WIDTH - 1 : 0] AHB_dtcm_read_data;

tcm_decoder u_tcm_decoder (
	.HCLK		(HCLK),
	.HRESETn	(HRESETn),
	.HSEL		(HSEL_S0),
	.HADDR		(HADDR_flash),
	.HSIZE		(HSIZE_flash),
	.HTRANS		(HTRANS_flash),
	.HWRITE		(HWRITE_flash),
	.HWDATA		(HWDATA_flash),
	.HREADY		(HREADY_S0),
	.HRDATA		(HRDATA_S0),
	.HREADY_flash	(HREADY_flash),
	.HRDATA_flash	(HRDATA_flash),
	.HSEL_flash	(HSEL_flash),
	.itcm_auto_load	(itcm_auto_load),
	.AHB_itcm_access		(AHB_itcm_access   ),
	.AHB_dtcm_access		(AHB_dtcm_access   ),
	.AHB_tcm_addr			(AHB_tcm_addr	   ),
	.AHB_tcm_byte_strobe		(AHB_tcm_byte_strobe	   ),
	.AHB_tcm_rd0_wr1		(AHB_tcm_rd0_wr1   ),
	.AHB_tcm_write_data		(AHB_tcm_write_data),
	.AHB_itcm_read_data		(AHB_itcm_read_data),
//	.AHB_dtcm_read_data		(AHB_dtcm_read_data)
	.AHB_dtcm_read_data		(0)


);

`ifdef KRV_HAS_ITCM
itcm u_itcm(
	.clk		(cpu_clk_g),
	.rstn		(cpu_rstn),
	.instr_itcm_addr		(instr_itcm_addr),
	.instr_itcm_access		(instr_itcm_access),
	.instr_itcm_read_data		(instr_itcm_read_data),
	.instr_itcm_read_data_valid	(instr_itcm_read_data_valid),

/*
	.data_itcm_rd0_wr1		(data_itcm_rd0_wr1),
	.data_itcm_byte_strobe		(data_itcm_byte_strobe),
	.data_itcm_access		(data_itcm_access),
	.data_itcm_ready		(data_itcm_ready),
	.data_itcm_addr			(data_itcm_addr),
	.data_itcm_write_data	(data_itcm_write_data),
	.data_itcm_read_data		(data_itcm_read_data),
	.data_itcm_read_data_valid	(data_itcm_read_data_valid),
*/
.AHB_itcm_access		(AHB_itcm_access   ),
.AHB_tcm_addr			(AHB_tcm_addr	   ),
.AHB_tcm_byte_strobe		(AHB_tcm_byte_strobe	   ),
.AHB_tcm_rd0_wr1		(AHB_tcm_rd0_wr1   ),
.AHB_tcm_write_data		(AHB_tcm_write_data),
.AHB_itcm_read_data		(AHB_itcm_read_data),


	.IAHB_ready	(IAHB_ready),
	.IAHB_read_data	(IAHB_read_data),
	.IAHB_read_data_valid	(IAHB_read_data_valid),
	.itcm_auto_load	(itcm_auto_load),
	.itcm_auto_load_addr	(itcm_auto_load_addr)

);
`else 
assign instr_itcm_read_data_valid = 1'b0;
assign instr_itcm_read_data = {`DATA_WIDTH {1'b0}};
assign AHB_itcm_read_data = {`DATA_WIDTH {1'b0}};
assign itcm_auto_load = 1'b0;
assign itcm_auto_load_addr = {`ADDR_WIDTH {1'b0}};
`endif

//-----------------------------------------------------//
//dtcm
//-----------------------------------------------------//
`ifdef KRV_HAS_DTCM
dtcm u_dtcm (
	.clk			(cpu_clk_g),
	.rstn			(cpu_rstn),
	.data_dtcm_access	(data_dtcm_access),
	.data_dtcm_ready	(data_dtcm_ready),
	.data_dtcm_rd0_wr1	(data_dtcm_rd0_wr1),
	.data_dtcm_byte_strobe		(data_dtcm_byte_strobe),
	.data_dtcm_addr		(data_dtcm_addr),
	.data_dtcm_wdata	(data_dtcm_write_data),
	.data_dtcm_rdata	(data_dtcm_read_data),
	.data_dtcm_rdata_valid	(data_dtcm_read_data_valid),
	.instr_dtcm_addr	(instr_dtcm_addr),
	.instr_dtcm_access	(instr_dtcm_access),
	.instr_dtcm_rdata	(instr_dtcm_read_data),
	.instr_dtcm_rdata_valid(instr_dtcm_read_data_valid),
	.dma_dtcm_access	(dma_dtcm_access),
	.dma_dtcm_ready		(dma_dtcm_ready),
	.dma_dtcm_rd0_wr1	(dma_dtcm_rd0_wr1),
	.dma_dtcm_addr		(dma_dtcm_addr),
	.dma_dtcm_wdata		(dma_dtcm_wdata),
	.dma_dtcm_rdata		(dma_dtcm_rdata),
	.dma_dtcm_rdata_valid	(dma_dtcm_rdata_valid)

);
`else
assign instr_dtcm_read_data_valid = 1'b0;
assign instr_dtcm_read_data = {`DATA_WIDTH {1'b0}};
assign data_dtcm_read_data_valid = 1'b0;
assign data_dtcm_read_data = {`DATA_WIDTH {1'b0}};
assign dma_dtcm_read_data_valid = 1'b0;
assign dma_dtcm_read_data = {`DATA_WIDTH {1'b0}};
`endif

//-----------------------------------------------------//
//core Instruction AHB interface
//-----------------------------------------------------//
IAHB u_IAHB_master(
	.HCLK		(HCLK),
	.HRESETn	(HRESETn),
	.HBUSREQ	(IAHB_HBUSREQ),
	.HLOCK		(IAHB_HLOCK),
	.HGRANT		(IAHB_HGRANT),
	.HREADY		(IAHB_HREADY),
	.HRESP		(IAHB_HRESP),
	.HRDATA		(IAHB_HRDATA),
	.HTRANS		(IAHB_HTRANS),
	.HADDR		(IAHB_HADDR),
	.HWRITE		(IAHB_HWRITE),
	.IAHB_access	(IAHB_access),	
	.IAHB_addr	(IAHB_addr),
	.IAHB_read_data	(IAHB_read_data),
	.IAHB_read_data_valid	(IAHB_read_data_valid),
	.IAHB_ready	(IAHB_ready),
	.itcm_auto_load	(itcm_auto_load),
	.itcm_auto_load_addr	(itcm_auto_load_addr)
);

//-----------------------------------------------------//
//core DATA AHB interface
//-----------------------------------------------------//
DAHB u_DAHB_master(
	.HCLK		(HCLK),
	.HRESETn	(HRESETn),
	.HBUSREQ	(DAHB_HBUSREQ),
	.HGRANT		(DAHB_HGRANT),
	.HREADY		(DAHB_HREADY),
	.HRESP		(DAHB_HRESP),
	.HRDATA		(DAHB_HRDATA),
	.HLOCK		(DAHB_HLOCK),
	.HTRANS		(DAHB_HTRANS),
	.HADDR		(DAHB_HADDR),
	.HWRITE		(DAHB_HWRITE),
	.HSIZE		(DAHB_HSIZE),
	.HBURST		(DAHB_HBURST),
	.HPROT		(DAHB_HPROT),
	.HWDATA		(DAHB_HWDATA),
	.cpu_clk	(cpu_clk_g),
	.cpu_resetn	(cpu_rstn),
	.DAHB_access	(DAHB_access),	
	.DAHB_rd0_wr1	(DAHB_rd0_wr1),		
	.DAHB_size		(DAHB_size),
	.DAHB_write_data	(DAHB_write_data),
	.DAHB_addr	(DAHB_addr),
	.DAHB_trans_buffer_full	(DAHB_trans_buffer_full),
	.DAHB_read_data	(DAHB_read_data),
	.DAHB_read_data_valid	(DAHB_read_data_valid)
);

//-----------------------------------------------------//
//main ahb
//-----------------------------------------------------//
ahb m_ahb(
.HCLK			(HCLK),
.HRESETn		(HRESETn),

//Master0
.HBUSREQ_from_M0	(IAHB_HBUSREQ),
.HLOCK_from_M0		(IAHB_HLOCK),
.HADDR_from_M0		(IAHB_HADDR),
.HTRANS_from_M0		(IAHB_HTRANS),
.HWRITE_from_M0		(1'b0),
.HWDATA_from_M0		(32'h0),
.HGRANT_to_M0		(IAHB_HGRANT),
.HRDATA_to_M0		(IAHB_HRDATA),
.HRESP_to_M0		(IAHB_HRESP),
.HREADY_to_M0		(IAHB_HREADY),

//Master1 
.HBUSREQ_from_M1	(DAHB_HBUSREQ),
.HLOCK_from_M1		(DAHB_HLOCK),
.HADDR_from_M1		(DAHB_HADDR),
.HSIZE_from_M1		(DAHB_HSIZE),
.HTRANS_from_M1		(DAHB_HTRANS),
.HWRITE_from_M1		(DAHB_HWRITE),
.HWDATA_from_M1		(DAHB_HWDATA),
.HGRANT_to_M1		(DAHB_HGRANT),
.HRDATA_to_M1		(DAHB_HRDATA),
.HRESP_to_M1		(DAHB_HRESP),
.HREADY_to_M1		(DAHB_HREADY),

//Master2
`ifdef KRV_HAS_DBG
.HBUSREQ_from_M2	(sb_HBUSREQ),
.HLOCK_from_M2		(sb_HLOCK),
.HADDR_from_M2		(sb_HADDR),
.HSIZE_from_M2		(sb_HSIZE),
.HTRANS_from_M2		(sb_HTRANS),
.HWRITE_from_M2		(sb_HWRITE),
.HWDATA_from_M2		(sb_HWDATA),
.HGRANT_to_M2		(sb_HGRANT),
.HRDATA_to_M2		(sb_HRDATA),
.HRESP_to_M2		(sb_HRESP),
.HREADY_to_M2		(sb_HREADY),
`else
.HBUSREQ_from_M2	(1'b0),
.HLOCK_from_M2		(1'b0),
.HADDR_from_M2		(32'h0),
.HTRANS_from_M2		(2'h0),
.HWRITE_from_M2		(1'b0),
.HWDATA_from_M2		(32'h0),
.HGRANT_to_M2		(),
.HRDATA_to_M2		(),
.HRESP_to_M2		(),
.HREADY_to_M2		(),
`endif

//Slave0
.HSEL_to_S0		(HSEL_S0	),
.HADDR_to_S0		(HADDR_flash	),
.HSIZE_to_S0		(HSIZE_flash	),
.HTRANS_to_S0		(HTRANS_flash	),
.HWRITE_to_S0		(HWRITE_flash	),
.HWDATA_to_S0		(HWDATA_flash	),
.HRDATA_from_S0		(HRDATA_S0	),
.HRESP_from_S0		(HRESP_flash	),
.HREADY_from_S0		(HREADY_S0	),

//Slave1
.HSEL_to_S1		(HSEL_kplic),
.HADDR_to_S1		(HADDR_kplic),
.HTRANS_to_S1		(HTRANS_kplic),
.HWRITE_to_S1		(HWRITE_kplic),
.HWDATA_to_S1		(HWDATA_kplic),
.HRDATA_from_S1		(HRDATA_kplic),
.HRESP_from_S1		(HRESP_kplic),
.HREADY_from_S1		(HREADY_kplic),

//Slave2
.HSEL_to_S2		(HSEL_core_timer),
.HADDR_to_S2		(HADDR_core_timer),
.HTRANS_to_S2		(HTRANS_core_timer),
.HWRITE_to_S2		(HWRITE_core_timer),
.HWDATA_to_S2		(HWDATA_core_timer),
.HRDATA_from_S2		(HRDATA_core_timer),
.HRESP_from_S2		(HRESP_core_timer),
.HREADY_from_S2		(HREADY_core_timer),

//Slave3
.HSEL_to_S3		(),
.HADDR_to_S3		(),
.HTRANS_to_S3		(),
.HWRITE_to_S3		(),
.HWDATA_to_S3		(),
.HRDATA_from_S3		(32'h0),
.HRESP_from_S3		(2'h0),
.HREADY_from_S3		(1'b1),

//Slave4
.HSEL_to_S4		(HSEL_apb	),
.HADDR_to_S4		(HADDR_apb	),
.HTRANS_to_S4		(HTRANS_apb	),
.HWRITE_to_S4		(HWRITE_apb	),
.HWDATA_to_S4		(HWDATA_apb	),
.HRDATA_from_S4		(HRDATA_apb	),
.HRESP_from_S4		(HRESP_apb	),
.HREADY_from_S4		(HREADY_apb	),

//Slave5
.HSEL_to_S5		(),
.HADDR_to_S5		(),
.HTRANS_to_S5		(),
.HWRITE_to_S5		(),
.HWDATA_to_S5		(),
.HRDATA_from_S5		(32'h0),
.HRESP_from_S5		(2'h0),
.HREADY_from_S5		(1'b1),

//Slave6
.HSEL_to_S6		(),
.HADDR_to_S6		(),
.HTRANS_to_S6		(),
.HWRITE_to_S6		(),
.HWDATA_to_S6		(),
.HRDATA_from_S6		(32'h0),
.HRESP_from_S6		(2'h0),
.HREADY_from_S6		(1'b1)

);

//-----------------------------------------------------//
//main apb
//-----------------------------------------------------//
apb_ss m_apb(
    .GPIO_IN		(GPIO_IN	),
    .GPIO_OUT		(GPIO_OUT	),
    .UART_RX		(UART_RX	),
    .UART_TX		(UART_TX	),
    .timer_int		(timer_int	),
    .HCLK		(HCLK),
    .HRESETn		(HRESETn),
    .HREADY		(1'b1),
    .HSEL		(HSEL_apb	),
    .HADDR		(HADDR_apb	),
    .HTRANS		(HTRANS_apb	),
    .HWRITE		(HWRITE_apb	),
    .HWDATA		(HWDATA_apb	),
    .HRDATA		(HRDATA_apb	),
    .HRESP		(HRESP_apb	),
    .HREADYOUT		(HREADY_apb	)
);


`ifdef ASIC
/*
flash_ss u_flash_ss(
);
ASIC flash
*/
`else
flash_sim u_flash_ss(
	.HCLK	(HCLK),
	.HRESETn(HRESETn),
	.HSEL	(HSEL_flash),
	.HADDR	(HADDR_flash),
	.HSIZE	(HSIZE_flash),
	.HWRITE	(HWRITE_flash),
	.HWDATA	(HWDATA_flash),
	.HREADY	(HREADY_flash),
	.HRDATA	(HRDATA_flash)
);

`endif


//-----------------------------------------------------//
//kplic
//-----------------------------------------------------//
`ifdef KRV_HAS_PLIC
kplic u_kplic (
.kplic_clk		(kplic_clk),
.kplic_rstn		(kplic_rstn),
.external_int		(external_int),
.kplic_int		(kplic_int),

	.HCLK		(HCLK),
	.HRESETn	(HRESETn),
	.HSEL		(HSEL_kplic),
	.HADDR		(HADDR_kplic),
	.HWRITE		(HWRITE_kplic),
	.HTRANS		(HTRANS_kplic),
	.HBURST		(HBURST_kplic),
	.HWDATA		(HWDATA_kplic),
	.HREADY		(HREADY_kplic),
	.HRESP		(HRESP_kplic),
	.HRDATA		(HRDATA_kplic)
);
`else
assign HREADY_kplic = 1'b1;
assign HRDATA_kplic = 32'h0;
assign HRESP_kplic = 2'h0;
assign kplic_int = 1'b0;
`endif

//-----------------------------------------------------//
//machine timer
//-----------------------------------------------------//
`ifdef KRV_HAS_MTIMER
core_timer u_core_timer (
	.core_timer_int		(core_timer_int),
	.HCLK		(HCLK),
	.HRESETn	(HRESETn),
	.HSEL		(HSEL_core_timer),
	.HADDR		(HADDR_core_timer),
	.HWRITE		(HWRITE_core_timer),
	.HTRANS		(HTRANS_core_timer),
	.HBURST		(HBURST_core_timer),
	.HWDATA		(HWDATA_core_timer),
	.HREADY		(HREADY_core_timer),
	.HRESP		(HRESP_core_timer),
	.HRDATA		(HRDATA_core_timer)
);
`else
assign HREADY_core_timer = 1'b1;
assign HRDATA_core_timer = 32'h0;
assign HRESP_core_timer = 2'h0;
assign core_timer_int = 1'b0;
`endif

`ifdef KRV_HAS_DBG
//-----------------------------------------------------//
//dtm
//-----------------------------------------------------//
wire dtm_req_valid;
wire dtm_req_ready;
wire [`DBUS_M_WIDTH - 1 : 0]	dtm_req_bits;
wire dm_resp_valid;
wire dm_resp_ready;
wire [`DBUS_S_WIDTH - 1 : 0]	dm_resp_bits;

dtm u_dtm (
.TDI			(TDI		),
.TDO			(TDO		),
.TCK			(TCK		),
.TMS			(TMS		),
.TRST			(TRST		),
.sys_clk		(cpu_clk	),
.sys_rstn		(cpu_rstn	),
.dtm_req_valid		(dtm_req_valid	),
.dtm_req_ready		(dtm_req_ready	),
.dtm_req_bits		(dtm_req_bits	),
.dm_resp_valid		(dm_resp_valid	),
.dm_resp_ready		(dm_resp_ready	),
.dm_resp_bits		(dm_resp_bits	)
);

//-----------------------------------------------------//
//dm
//-----------------------------------------------------//
dm u_dm(
	.HCLK		(HCLK),
	.HRESETn	(HRESETn),
	.HBUSREQ	(sb_HBUSREQ),
	.HGRANT		(sb_HGRANT),
	.HREADY		(sb_HREADY),
	.HRESP		(sb_HRESP),
	.HRDATA		(sb_HRDATA),
	.HLOCK		(sb_HLOCK),
	.HTRANS		(sb_HTRANS),
	.HADDR		(sb_HADDR),
	.HWRITE		(sb_HWRITE),
	.HSIZE		(sb_HSIZE),
	.HBURST		(sb_HBURST),
	.HPROT		(sb_HPROT),
	.HWDATA		(sb_HWDATA),

.sys_clk		(cpu_clk	),
.sys_rstn		(cpu_rstn	),
.dtm_req_valid		(dtm_req_valid	),
.dtm_req_ready		(dtm_req_ready	),
.dtm_req_bits		(dtm_req_bits	),
.dm_resp_valid		(dm_resp_valid	),
.dm_resp_ready		(dm_resp_ready	),
.dm_resp_bits		(dm_resp_bits	),
.resumereq_w1		(resumereq_w1	),
.dbg_reg_access		(dbg_reg_access	),
.dbg_wr1_rd0		(dbg_wr1_rd0	),
.dbg_regno		(dbg_regno	),
.dbg_write_data		(dbg_write_data	),
.dbg_read_data_valid	(dbg_read_data_valid),
.dbg_read_data		(dbg_read_data	)
);


`endif

endmodule
