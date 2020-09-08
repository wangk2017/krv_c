
//==============================================================||
// File Name: 		wb_ctrl.v				||
// Author:    		Kitty Wang				||
// Description: 						||
//	      		write back control                	|| 
// History:   							||
//                      2017/9/26 				||
//                      First version				||
//===============================================================
`include "core_defines.vh"
module wb_ctrl (
//global signals
input wire cpu_clk,				//cpu clock
input wire cpu_rstn,				//cpu reset, active low

//interface with dmem_ctrl
input wire [`DATA_WIDTH - 1 : 0] alu_result_wb,	//alu result at WB stage	     	
input wire alu_result_valid_wb,		       	//alu result valid signal at WB stage 	
input load_wb,					//load at WB stage		
input wire [`DATA_WIDTH - 1 : 0] load_data_wb,	//load data at WB stage	
input wire load_data_valid_wb,			//load data valid at WB stage	
output wire wb_ready,

//interface with gprs
output reg [`DATA_WIDTH - 1 : 0] wr_data_wb,    //final write back data    
output reg wr_valid_wb				//final write back data valid
);


//data write back
wire wb_type;
assign wb_type = load_wb;
always @ *
begin
	case (wb_type)
	1'b0: begin					//ALU
		wr_data_wb = alu_result_wb;
		wr_valid_wb = alu_result_valid_wb;
	end
	1'b1: begin					//LOAD
		wr_data_wb = load_data_wb;
		wr_valid_wb =load_data_valid_wb;
	end
	default: begin
		wr_data_wb = {`DATA_WIDTH{1'b0}};
		wr_valid_wb = 1'b0;
	end
	endcase
end

assign wb_ready = 1;

endmodule
