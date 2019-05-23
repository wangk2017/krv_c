//====================================================================//
// File Name: 		async_fifo.v
// Author:    		Kitty Wang
// Description: 
//	      		asynchronize FIFO 
// History:   		
//                      2017/8/19 
//                      First version
//			Modelsim compile successfully
//====================================================================//

module async_fifo (
//write side signals
wr_clk,
wr_rstn,
wr_valid,
wr_data,
//read side signals
rd_clk,
rd_rstn,
rd_ready,
rd_valid,
rd_data,
//flags
full,
empty
);

parameter DATA_WIDTH=8;
parameter FIFO_DEPTH=8;
//parameter PTR_WIDTH log2(FIFO_DEPTH) ;
parameter PTR_WIDTH=3;
// Port Declaration
// 1: Write Side
input wr_clk;      			// clock of write side
input wr_rstn;     			// negetive reset of write side
input wr_valid;	   			// signal indication of the write data valid
input [DATA_WIDTH - 1 : 0] wr_data;    // write data

// 2: Read Side
input rd_clk;      			// clock of read side
input rd_rstn;     			// negetive reset of read side
input rd_ready;	   			// signal indication of the read side is ready to receive data

output rd_valid;			// signal indication of the read data valid 
output [DATA_WIDTH - 1 : 0] rd_data;    // read data

output empty;
output full; 
// Wires
// 1: wr_ctrl with storage connection
wire w_en;
wire [PTR_WIDTH  : 0]  w_addr;

// 2: rd_ctrl with storage connection
wire r_en;
wire [PTR_WIDTH  : 0]  r_addr;

// 3: wr_ctrl and rd_ctrl connection
wire [PTR_WIDTH  : 0]  rptr_gray;
wire [PTR_WIDTH  : 0]  wptr_gray;


// First-level block instantiation
// including the following blocks:
// 1: wr_ctrl for write control
// 2: rd_ctrl for read control
// 3: fifo_storage for SRAM

// 1: wr_ctrl

wr_ctrl #(.DATA_WIDTH (DATA_WIDTH), .FIFO_DEPTH(FIFO_DEPTH),.PTR_WIDTH(PTR_WIDTH))  wr_ctrl_inst(
//input
.wr_clk		(wr_clk),
.wr_rstn	(wr_rstn),
.wr_valid	(wr_valid),
.rptr_gray,
//output
.full		(full),
.wptr_gray	(wptr_gray),
.w_en		(w_en),
.w_addr		(w_addr)
);

// 2: rd_ctrl

rd_ctrl #(.DATA_WIDTH (DATA_WIDTH), .FIFO_DEPTH(FIFO_DEPTH),.PTR_WIDTH(PTR_WIDTH))  rd_ctrl_inst (
//input
.rd_clk		(rd_clk),
.rd_rstn	(rd_rstn),
.rd_ready	(rd_ready),
.wptr_gray	(wptr_gray),
//output
.empty		(empty),
.rptr_gray	(rptr_gray),
.r_en		(r_en),
.r_addr		(r_addr)
);

// 3: fifo_storage

fifo_storage #(.DATA_WIDTH (DATA_WIDTH), .FIFO_DEPTH(FIFO_DEPTH),.PTR_WIDTH(PTR_WIDTH)) fifo_storage_inst (
//input
.wr_clk		(wr_clk),
.wr_rstn	(wr_rstn),
.w_en		(w_en),
.w_addr		(w_addr),
.wr_data	(wr_data),
.r_en		(r_en),
.r_addr		(r_addr),
//output
.rd_valid	(rd_valid),
.rd_data	(rd_data)
);

endmodule



module wr_ctrl (
//input
wr_clk,
wr_rstn,
wr_valid,
rptr_gray,
//output
full,
wptr_gray,
w_en,
w_addr
);
parameter DATA_WIDTH=8;
parameter FIFO_DEPTH=32;
//parameter PTR_WIDTH log2(FIFO_DEPTH) ;
parameter PTR_WIDTH=5;
// Port Declaration
// 1: from write side
input wr_clk;      			// clock of write side
input wr_rstn;     			// negetive reset of write side
input wr_valid;	   			// signal indication of the write data valid

// 2: to fifo_storage
output w_en;				// sram write enable
output [PTR_WIDTH : 0] w_addr;         // sram write address

// 3: to rd_ctrl
output  [PTR_WIDTH : 0]  wptr_gray;

// 4: from rd_ctrl
input  [PTR_WIDTH : 0]  rptr_gray;

//flag
output full; 

//Wires
reg [PTR_WIDTH : 0] wptr_binary;

// Logic Start
//------------------------------------------------------------------//
// synchronizer of the rptr_gray from rd_clk domain to wr_clk domain
//------------------------------------------------------------------//
reg  [PTR_WIDTH : 0]  rptr_gray_sync1, rptr_gray_sync2;

always @ (posedge wr_clk or negedge wr_rstn)
begin
	if (!wr_rstn)
	begin
		rptr_gray_sync1 <= {PTR_WIDTH{1'b0}};	
		rptr_gray_sync2 <= {PTR_WIDTH{1'b0}};	
	end
	else
	begin
		rptr_gray_sync1 <= rptr_gray;	
		rptr_gray_sync2 <= rptr_gray_sync1;	
	end
end

//------------------------------------------------------------------//
// convert synced rptr_gray to rptr_binary                                 
//------------------------------------------------------------------//
reg  [PTR_WIDTH : 0]  rptr_synced_binary;
integer i;

always @ *
begin
	rptr_synced_binary[PTR_WIDTH] = rptr_gray_sync2[PTR_WIDTH];
	for (i=PTR_WIDTH-1; i>=0; i=i-1)
	begin
	  rptr_synced_binary[i] = rptr_synced_binary[i+1] ^
rptr_gray_sync2[i];
	end
end

//------------------------------------------------------------------//
// full flag generation                                             
//------------------------------------------------------------------//
wire full;

assign full = (wptr_binary[PTR_WIDTH] ^ rptr_synced_binary[PTR_WIDTH]) &&
(wptr_binary[PTR_WIDTH-1 : 0] == rptr_synced_binary[PTR_WIDTH-1 : 0]);



//------------------------------------------------------------------//
// w_en generation                                             
//------------------------------------------------------------------//
wire w_en;
assign w_en = wr_valid && !full;

//------------------------------------------------------------------//
// wptr_binary generation                                             
//------------------------------------------------------------------//
assign w_addr = wptr_binary;

always @(posedge wr_clk or negedge wr_rstn)
begin
	if (!wr_rstn)
	begin
		wptr_binary <= {PTR_WIDTH{1'b0}};
	end
	else
	begin
		if (w_en)
		begin
			wptr_binary <= wptr_binary + {{PTR_WIDTH-1{1'b0}},1'b1};
		end
		else
		begin
			wptr_binary <= wptr_binary;
		end
	end

end

//------------------------------------------------------------------//
// wptr_gray generation                                             
//------------------------------------------------------------------//
wire [PTR_WIDTH : 0] wptr_gray;
assign wptr_gray = (wptr_binary >> 1'b1 ) ^ wptr_binary;

endmodule


module rd_ctrl (
//input
rd_clk,
rd_rstn,
rd_ready,
wptr_gray,
//output
empty,
rptr_gray,
r_en,
r_addr
);
parameter DATA_WIDTH=8;
parameter FIFO_DEPTH=32;
//parameter PTR_WIDTH log2(FIFO_DEPTH) ;
parameter PTR_WIDTH=5;
// Port declaration
// 1: from read side
input rd_clk;
input rd_rstn;
input rd_ready;

// 2: with wr_ctrl block
input [PTR_WIDTH : 0] wptr_gray; 
output [PTR_WIDTH : 0] rptr_gray; 

// 3: to fifo_storage
output r_en;
output [PTR_WIDTH : 0] r_addr;

//flag
output empty; 

// Wires
reg [PTR_WIDTH : 0] rptr_binary;

// Logic Start
//------------------------------------------------------------------//
// synchronizer of the wptr_gray from wr_clk domain to rd_clk domain
//------------------------------------------------------------------//
reg  [PTR_WIDTH : 0]  wptr_gray_sync1, wptr_gray_sync2;

always @ (posedge rd_clk or negedge rd_rstn)
begin
	if (!rd_rstn)
	begin
		wptr_gray_sync1 <= {PTR_WIDTH{1'b0}};	
		wptr_gray_sync2 <= {PTR_WIDTH{1'b0}};	
	end
	else
	begin
		wptr_gray_sync1 <= wptr_gray;	
		wptr_gray_sync2 <= wptr_gray_sync1;	
	end
end

//------------------------------------------------------------------//
// convert synced wptr_gray to wptr_binary                                 
//------------------------------------------------------------------//
reg  [PTR_WIDTH : 0]  wptr_synced_binary;
integer i;

always @ *
begin
	wptr_synced_binary[PTR_WIDTH] = wptr_gray_sync2[PTR_WIDTH];
	for (i=PTR_WIDTH-1; i>=0; i=i-1)
	begin
	  wptr_synced_binary[i] = wptr_synced_binary[i+1] ^
wptr_gray_sync2[i];
	end
end

//------------------------------------------------------------------//
// empty flag generation                                             
//------------------------------------------------------------------//
wire empty;

assign empty = rptr_binary[PTR_WIDTH : 0] == wptr_synced_binary[PTR_WIDTH : 0]; 




//------------------------------------------------------------------//
// r_en generation                                             
//------------------------------------------------------------------//
wire r_en;
assign r_en = rd_ready && !empty;

//------------------------------------------------------------------//
// rptr_binary generation                                             
//------------------------------------------------------------------//
assign r_addr = rptr_binary;

always @(posedge rd_clk or negedge rd_rstn)
begin
	if (!rd_rstn)
	begin
		rptr_binary <= {PTR_WIDTH{1'b0}};
	end
	else
	begin
		if (r_en)
		begin
			rptr_binary <= rptr_binary + {{PTR_WIDTH-1{1'b0}},1'b1};
		end
		else
		begin
			rptr_binary <= rptr_binary;
		end
	end

end

//------------------------------------------------------------------//
// rptr_gray generation                                             
//------------------------------------------------------------------//
wire [PTR_WIDTH : 0] rptr_gray;
assign rptr_gray = rptr_binary ^ (rptr_binary >> 1'b1);


endmodule

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
parameter FIFO_DEPTH=32;
//parameter PTR_WIDTH log2(FIFO_DEPTH) ;
parameter PTR_WIDTH=5;
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
input [PTR_WIDTH : 0] w_addr;

// 4: from rd_ctrl block
input r_en;
input [PTR_WIDTH : 0] r_addr;

//Wires
reg [DATA_WIDTH - 1 : 0] fifo_mem [FIFO_DEPTH - 1 : 0];

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



