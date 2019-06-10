task dtm_write_reg;
input [31:0] write_data;
input [5:0] write_addr;

begin
@(posedge DUT.cpu_clk);
	force DUT.u_dm.dtm_req_valid = 1'b1;
	force DUT.u_dm.dtm_req_bits = {write_data,write_addr,2'b10};
@(posedge DUT.cpu_clk);
	force DUT.u_dm.dtm_req_valid = 1'b0;
end

endtask


task dtm_read_reg;

input[5:0] read_addr;

begin
	@(posedge DUT.cpu_clk);
	force DUT.u_dm.dtm_req_valid = 1'b1;
	force DUT.u_dm.dtm_req_bits = {32'h0,read_addr,2'b01};
	@(posedge DUT.cpu_clk);
	force DUT.u_dm.dtm_req_valid = 1'b0;

end

endtask
