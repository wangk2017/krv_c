
module fifo_storage (
//input
wr_clk,
wr_rstn,
w_en,
w_addr,
wr_data,
r_en,
r_addr,
//output
rd_valid,
rd_data
);
parameter DATA_WIDTH=8;
parameter FIFO_DEPTH=8;
//parameter PTR_WIDTH log2(FIFO_DEPTH) ;
parameter PTR_WIDTH=3;
// Port declaration
// 1: from write side
input wr_clk;
input wr_rstn;
input [DATA_WIDTH - 1 : 0] wr_data;

// 2: to read side
output rd_valid;
output [DATA_WIDTH - 1 : 0] rd_data;

// 3: from wr_ctrl block
input w_en;
input [PTR_WIDTH - 1 : 0] w_addr;

// 4: from rd_ctrl block
input r_en;
input [PTR_WIDTH - 1 : 0] r_addr;

//Wires
reg [DATA_WIDTH - 1 : 0] fifo_mem [FIFO_DEPTH - 1 : 0];

/*
// for test
wire [DATA_WIDTH - 1 : 0] fifo_mem0, fifo_mem1,fifo_mem2, fifo_mem3, fifo_mem4, fifo_mem5, fifo_mem6, fifo_mem7;
assign fifo_mem0 = fifo_mem[0];
assign fifo_mem1 = fifo_mem[1];
assign fifo_mem2 = fifo_mem[2];
assign fifo_mem3 = fifo_mem[3];
assign fifo_mem4 = fifo_mem[4];
assign fifo_mem5 = fifo_mem[5];
assign fifo_mem6 = fifo_mem[6];
assign fifo_mem7 = fifo_mem[7];
*/

//Logic start

always @(posedge wr_clk)
begin
	if (w_en)
	begin
		fifo_mem[w_addr] <=wr_data;
	end
end

assign rd_valid = r_en;
assign rd_data  = fifo_mem[r_addr];

endmodule



