//==============================================================||
// File Name: 		dmem.v					||
// Author:    		Kitty Wang				||
// Description: 						||
//	      		data memory                       	|| 
// History:   							||
//                      2017/9/26 				||
//                      First version				||
//===============================================================
`include "ahb_defines.vh"
module flash_sim(
	input wire HCLK,
	input wire HRESETn,
	input wire HSEL,
	input wire [`AHB_ADDR_WIDTH - 1 : 0] HADDR,
	input wire [2:0] HSIZE,
	input wire HWRITE,
	input wire [`AHB_DATA_WIDTH - 1 : 0] HWDATA,
	output wire HREADY,
	output reg [`AHB_DATA_WIDTH - 1 : 0] HRDATA
);

reg [`AHB_DATA_WIDTH - 1 : 0] mem [81919:0];

reg [31:0] ip_addr;
reg wr1_rd0;
reg access;
reg [2:0] size;

always @ (posedge HCLK)
begin
	if(!HRESETn)
	begin
		ip_addr <= 0;
		wr1_rd0 <= 0;
		access <= 0;
		size <= 0;
	end
	else if(HSEL)
	begin
		ip_addr <= HADDR;
		wr1_rd0 <= HWRITE;
		access <= 1;
		size <= HSIZE;
	end
	else
	begin
		access <= 0;
	end
end


wire [19:2] HADDR_wr = ip_addr[19:2];

wire[1:0] mem_wr_strobe = ip_addr[1:0];
wire [31:0] mem_1013f = mem[65855];

always @ (posedge HCLK)
begin
	if(access && wr1_rd0)
	begin
		case (mem_wr_strobe)
		2'b00: 
		begin
			case(size)
			3'b010: mem[HADDR_wr] <= HWDATA;
			3'b001: mem[HADDR_wr][15:0] <= HWDATA[15:0];
			3'b000: mem[HADDR_wr][7:0] <= HWDATA[7:0];
			endcase
		end
		2'b01: 
		begin
			case(size)
			3'b010: mem[HADDR_wr][31:8] <= HWDATA[31:8];
			3'b001: mem[HADDR_wr][23:8] <= HWDATA[23:8];
			3'b000: mem[HADDR_wr][15:8] <= HWDATA[15:8];
			endcase
		end
		2'b10:
		begin
			case(size)
			3'b010,001: mem[HADDR_wr][31:16] <= HWDATA[31:16];
			3'b000: mem[HADDR_wr][23:16] <= HWDATA[23:16];
			endcase
		end
		2'b11: mem[HADDR_wr][31:24] <= HWDATA[31:24];
		endcase
	end
end


wire [19:2] HADDR_rd = HADDR[19:2];

always @ (posedge HCLK)
begin
	if(HSEL && !HWRITE)
	begin
		HRDATA <= mem[HADDR_rd];
	end
end


assign HREADY = 1;


endmodule
