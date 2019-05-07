/*
 Licensed under the Apache License, Version 2.0 (the "License"),         
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
// File Name: 		apb.v					||
// Author:    		Kitty Wang				||
// Description: 						||
//	      		APB  				    	|| 
// History:   							||
//                      First version				||
//===============================================================


module apb(
//ahb2apb interface
input  [31:0] PADDR,
input         PENABLE,
input         PSEL,
input  [31:0] PWDATA,
input         PWRITE,
output [31:0] PRDATA,
output        PREADY,
output        PSLVERR,

//common slave interface
output [31:0] PADDRS,
output        PENABLES,
output [31:0] PWDATAS,
output        PWRITES,

//slave1 interface
output        PSELS1,
input  [31:0] PRDATAS1,
input         PREADYS1,
input         PSLVERRS1,

//slave2 interface
output        PSELS2,
input  [31:0] PRDATAS2,
input         PREADYS2,
input         PSLVERRS2,

//slave3 interface
output        PSELS3,
input  [31:0] PRDATAS3,
input         PREADYS3,
input         PSLVERRS3,

//slave4 interface
output        PSELS4,
input  [31:0] PRDATAS4,
input         PREADYS4,
input         PSLVERRS4
);


assign PADDRS 	= PADDR;
assign PENABLES = PENABLE;
assign PWDATAS 	= PWDATA;
assign PWRITES 	= PWRITE;

wire[3:0] slave_slot = PADDR[15:12];
assign PSELS1 = slave_slot == 4'b0001;
assign PSELS2 = slave_slot == 4'b0010;
assign PSELS3 = slave_slot == 4'b0011;
assign PSELS4 = slave_slot == 4'b0100;

reg [31:0] iPRDATA;
reg        iPREADY;
reg        iPSLVERR;

always @ *
begin
	case(slave_slot)
	4'b0001: begin
		iPRDATA  = PRDATAS1;
		iPREADY  = PREADYS1;
		iPSLVERR = PSLVERRS1;
	end
	4'b0010: begin
		iPRDATA  = PRDATAS2;
		iPREADY  = PREADYS2;
		iPSLVERR = PSLVERRS2;
	end
	4'b0011: begin
		iPRDATA  = PRDATAS3;
		iPREADY  = PREADYS3;
		iPSLVERR = PSLVERRS3;
	end
	4'b0100: begin
		iPRDATA  = PRDATAS4;
		iPREADY  = PREADYS4;
		iPSLVERR = PSLVERRS4;
	end
	default: begin
		iPRDATA  = 32'h0;
		iPREADY  = 1'b1;
		iPSLVERR = 1'b0;
	end
	endcase
end

assign PRDATA = iPRDATA;
assign PREADY = iPREADY;
assign PSLVERR= iPSLVERR;

endmodule
