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

//====================================================================//
// File Name: 		sync_fifo.v
// Author:    		Kitty Wang
// Description: 
//	      		synchronize FIFO 
// History:   		
//                      2017/8/19 
//                      First version
//			Modelsim compile successfully
//====================================================================//

module sync_fifo (
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
full,
empty
);

parameter DATA_WIDTH=8;
parameter FIFO_DEPTH=8;
parameter PTR_WIDTH=$clog2(FIFO_DEPTH) ;
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

output full;
output empty;
// Wires
// 1: wr_ctrl with storage connection
wire w_en;
wire [PTR_WIDTH - 1  : 0]  w_addr;

// 2: rd_ctrl with storage connection
wire r_en;
wire [PTR_WIDTH - 1 : 0]  r_addr;


//Wires
reg [PTR_WIDTH : 0] wptr_binary;
reg [PTR_WIDTH : 0] rptr_binary;

//------------------------------------------------------------------//
// full flag generation                                             
//------------------------------------------------------------------//
wire full;

assign full = (wptr_binary[PTR_WIDTH] ^ rptr_binary[PTR_WIDTH]) &&
(wptr_binary[PTR_WIDTH-1 : 0] == rptr_binary[PTR_WIDTH-1 : 0]);



//------------------------------------------------------------------//
// w_en generation                                             
//------------------------------------------------------------------//

assign w_en = wr_valid && !full;

assign w_addr = wptr_binary[PTR_WIDTH - 1 : 0];

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
// empty flag generation                                             
//------------------------------------------------------------------//
wire empty;

assign empty = rptr_binary[PTR_WIDTH : 0] == wptr_binary[PTR_WIDTH : 0]; 


//------------------------------------------------------------------//
// r_en generation                                             
//------------------------------------------------------------------//

assign r_en = rd_ready && !empty;

//------------------------------------------------------------------//
// rptr_binary generation                                             
//------------------------------------------------------------------//
assign r_addr = rptr_binary[PTR_WIDTH - 1 : 0];

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

//  fifo_storage

fifo_storage #(.DATA_WIDTH (DATA_WIDTH), .FIFO_DEPTH(FIFO_DEPTH),.PTR_WIDTH(PTR_WIDTH)) fifo_storage_inst (
//input
.wr_clk		(wr_clk),
.wr_rstn	(wr_rstn),
.w_en		(w_en),
.w_addr		(w_addr),
.wr_data	(wr_data),
.rd_clk		(rd_clk),
.rd_rstn	(rd_rstn),
.r_en		(r_en),
.r_addr		(r_addr),
//output
.rd_valid	(rd_valid),
.rd_data	(rd_data)
);

endmodule


