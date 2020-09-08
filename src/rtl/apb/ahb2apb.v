//==============================================================||
// File Name: 		ahb2apb.v				||
// Author:    		Kitty Wang				||
// Description: 						||
//	      		AHB2APB				    	|| 
// History:   							||
//                      First version				||
//===============================================================


// ahb2apb
module ahb2apb(
//ahb interface
input  [31:0] HADDR,
input         HCLK,
input         HREADY,
input         HRESETN,
input         HSEL,
input  [1:0]  HTRANS,
input  [31:0] HWDATA,
input         HWRITE,
output [31:0] HRDATA,
output        HREADYOUT,
output [1:0]  HRESP,

//apb interface
input  [31:0] PRDATA,
input         PREADY,
input         PSLVERR,
output        PENABLE,
output        PSEL,
output [31:0] PADDR,
output [31:0] PWDATA,
output        PWRITE
);

reg iPSEL;

always @ (posedge HCLK or negedge HRESETN)
begin
	if(!HRESETN)
	begin
		iPSEL <= 1'b0;
	end
	else
	begin
		if(HSEL)
		begin
			iPSEL <= 1'b1;
		end
		else if(PENABLE && PREADY)
		begin
			iPSEL <= 1'b0;
		end
		
	end
end

reg PSEL_d;
always @ (posedge HCLK or negedge HRESETN)
begin
	if(!HRESETN)
	begin
		PSEL_d <= 1'b0;
	end
	else
	begin
		PSEL_d <= PSEL;
	end
end

wire PSEL_rising = PSEL && !PSEL_d;


reg iPENABLE;
always @ (posedge HCLK or negedge HRESETN)
begin
	if(!HRESETN)
	begin
		iPENABLE <= 1'b0;
	end
	else
	begin
		if(PSEL_rising)
		begin
			iPENABLE <= 1'b1;
		end
		else if(PREADY)
		begin
			iPENABLE <= 1'b0;
		end
	end
end

reg [31:0] iPADDR;
reg [31:0] iPWDATA;
reg        iPWRITE;

always @ (posedge HCLK or negedge HRESETN)
begin
	if(!HRESETN)
	begin
		iPADDR <= 32'h0;
		iPWRITE <= 1'b0;
	end
	else
	begin
		if(HSEL)
		begin
			iPADDR <= HADDR;
			iPWRITE <= HWRITE;
		end
	end
end
always @ (posedge HCLK or negedge HRESETN)
begin
	if(!HRESETN)
	begin
		iPWDATA <= 32'h0;
	end
	else
	begin
		if(PSEL)
		begin
			iPWDATA <= HWDATA;
		end
	end
end


assign PSEL = iPSEL;
assign PENABLE = iPENABLE;
assign PADDR = iPADDR;
assign PWRITE = iPWRITE;
assign PWDATA = iPWDATA;
assign HREADYOUT = PREADY;
assign HRDATA = PRDATA;
assign HRESP = 2'b00;

endmodule
