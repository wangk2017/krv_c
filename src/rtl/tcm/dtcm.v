
//==============================================================||
// File Name: 		dtcm.v					||
// Author:    		Kitty Wang				||
// Description: 						||
//	      		tightly coupled memory for data		||
// History:   							||
//===============================================================
`include "top_defines.vh"
module dtcm (
	//global signals
	input clk,						//clock
	input rstn,						//reset, active low

	//with core data interface
	input data_dtcm_access,					//access signal
	output wire data_dtcm_ready,				//DTCM is ready to data IF
	input data_dtcm_rd0_wr1,				//access cmd, rd=0;wr=1
	input wire [3:0] data_dtcm_byte_strobe,			//write strobe
	input [`ADDR_WIDTH - 1 : 0] data_dtcm_addr,		//access address
	input wire [`DATA_WIDTH - 1 : 0] data_dtcm_wdata,	//write data
	output wire [`DATA_WIDTH - 1 : 0] data_dtcm_rdata,	//read data
	output reg data_dtcm_rdata_valid,			//read data valid

	//with core instruction interface
	input AHB_dtcm_access,					//access signal
	input AHB_tcm_rd0_wr1,					//access cmd, rd=0;wr=1
	input wire [3:0] AHB_tcm_byte_strobe,			//write strobe
	input [`ADDR_WIDTH - 1 : 0] AHB_tcm_addr,		//address
	input wire [`DATA_WIDTH - 1 : 0] AHB_tcm_wdata,		//write data
	output wire [`DATA_WIDTH - 1 : 0] AHB_dtcm_rdata,	//read data
	output reg AHB_dtcm_rdata_valid,			//read data valid

	//with DMA
	input dma_dtcm_access,					//access signal	
	output wire dma_dtcm_ready,				//DTCM ready to DMA
	input dma_dtcm_rd0_wr1,					//access cmd, rd=0; wr=1
	input [`ADDR_WIDTH - 1 : 0] dma_dtcm_addr,		//access address
	input wire [`DATA_WIDTH - 1 : 0] dma_dtcm_wdata,	//write data
	output wire [`DATA_WIDTH - 1 : 0] dma_dtcm_rdata,	//read data
	output reg dma_dtcm_rdata_valid				//read data valid

);


//----------------------------------------------------------------//
//DTCM access operation
//----------------------------------------------------------------//
	wire dtcm_access;			
	wire dtcm_rd0_wr1;		
	wire dtcm_wen;
	wire [`ADDR_WIDTH - 1 : 0] dtcm_addr;	
	wire [`DATA_WIDTH - 1 : 0] dtcm_wdata;	
	wire [3:0] dtcm_byte_strobe;

	assign dtcm_access = data_dtcm_access || dma_dtcm_access || AHB_dtcm_access;
	assign dtcm_rd0_wr1 = data_dtcm_rd0_wr1 || dma_dtcm_rd0_wr1 || AHB_tcm_rd0_wr1;
	assign dtcm_wen = dtcm_access & dtcm_rd0_wr1;
	assign dtcm_addr = dma_dtcm_access? dma_dtcm_addr : (data_dtcm_access? data_dtcm_addr : AHB_tcm_addr);
	assign dtcm_wdata = dma_dtcm_access? dma_dtcm_wdata : (data_dtcm_access ? data_dtcm_wdata : AHB_tcm_wdata);
	assign dtcm_byte_strobe = data_dtcm_access ? data_dtcm_byte_strobe : AHB_tcm_byte_strobe;

	assign data_dtcm_ready = (!(dma_dtcm_access && dma_dtcm_rd0_wr1)) || (!data_dtcm_rd0_wr1 && (!(dma_dtcm_access && dma_dtcm_rd0_wr1 && (dma_dtcm_addr == data_dtcm_addr))));
	assign dma_dtcm_ready = dma_dtcm_access;

wire[14 : 2] dtcm_word_addr = dtcm_addr[14 : 2];
`ifdef ASIC
wire [`DATA_WIDTH - 1 : 0] dtcm_rdata;
/*
sram_4Kx32 dtcm (
    .CLK	(clk),
    .RADDR	(dtcm_word_addr),
    .WADDR	(dtcm_word_addr),
    .WD		(dtcm_wdata),
    .WEN	(dtcm_wen),
    .RD		(dtcm_rdata)
);
*/
`else
reg [`DATA_WIDTH - 1 : 0] dtcm [`DTCM_SIZE - 1 : 0];
always @ (posedge clk or negedge rstn)
begin
	if(dtcm_wen)
	begin
		if(dtcm_byte_strobe[3])
			dtcm[dtcm_word_addr][31:24] <= dtcm_wdata[31:24];
		if(dtcm_byte_strobe[2])
			dtcm[dtcm_word_addr][23:16] <= dtcm_wdata[23:16];
		if(dtcm_byte_strobe[1])
			dtcm[dtcm_word_addr][15:8]  <= dtcm_wdata[15:8];
		if(dtcm_byte_strobe[0])
			dtcm[dtcm_word_addr][7:0]   <= dtcm_wdata[7:0];
	end

end

reg [`DATA_WIDTH - 1 : 0] dtcm_rdata;
always @ (posedge clk or negedge rstn)
begin
	if(!rstn)
	begin
		dtcm_rdata <= 32'h0;
	end
	else
	begin
		dtcm_rdata <= dtcm[dtcm_word_addr];
	end
end
`endif

always @ (posedge clk or negedge rstn)
begin
	if(!rstn)
	begin
		data_dtcm_rdata_valid <= 1'b0;
	end
	else
	begin
		data_dtcm_rdata_valid <= data_dtcm_access & (!data_dtcm_rd0_wr1);
	end
end

always @ (posedge clk or negedge rstn)
begin
	if(!rstn)
	begin
		AHB_dtcm_rdata_valid <= 1'b0;
	end
	else
	begin
		AHB_dtcm_rdata_valid <= AHB_dtcm_access && !data_dtcm_access;
	end
end


always @ (posedge clk or negedge rstn)
begin
	if(!rstn)
	begin
		dma_dtcm_rdata_valid <= 1'b0;
	end
	else
	begin
		dma_dtcm_rdata_valid <= dma_dtcm_access & (!dma_dtcm_rd0_wr1);
	end
end



assign data_dtcm_rdata = dtcm_rdata;

assign AHB_dtcm_rdata = dtcm_rdata;

assign dma_dtcm_rdata = dtcm_rdata;


endmodule
