//configure breakpoint by debugger (with a dtm driver)
initial
begin
	$display ("=============================================\n");
	$display ("running test to debug breakpoint\n");
	$display ("=============================================\n");
@(posedge DUT.cpu_clk);
@(posedge DUT.cpu_clk);
@(posedge DUT.cpu_clk);
@(posedge DUT.cpu_clk);
@(posedge DUT.cpu_clk);
	$display ("=============================================\n");
	$display ("The dtm driver start                         \n");
	$display ("=============================================\n");
	$display ("Configure the breakpoint          \n");
	$display ("                                             \n");
	$display ("step1:  configure tselect for trigger0       \n");

	force DUT.u_dm.dtm_req_valid = 1'b1;
	force DUT.u_dm.dtm_req_bits = {32'h0000,6'h04,2'b10};
@(posedge DUT.cpu_clk);
	force DUT.u_dm.dtm_req_valid = 1'b0;
@(posedge DUT.cpu_clk);
	force DUT.u_dm.dtm_req_valid = 1'b1;
	force DUT.u_dm.dtm_req_bits = {8'h0,1'b0,3'h0,1'b0,1'b0,1'b1,1'b1,16'h07a0,6'h17,2'b10};
@(posedge DUT.cpu_clk);
	force DUT.u_dm.dtm_req_valid = 1'b0;

	$display ("                                             \n");
	$display ("step2:  configure tdata1 for trigger0       \n");
@(posedge DUT.cpu_clk);
	force DUT.u_dm.dtm_req_valid = 1'b1;
	force DUT.u_dm.dtm_req_bits = {4'h2,1'b1,6'h0,1'b0,1'b0,1'b0,2'h0,4'h1,1'b0,4'h0,1'b1,3'h0,1'b1,2'h0,6'h04,2'b10};
@(posedge DUT.cpu_clk);
	force DUT.u_dm.dtm_req_valid = 1'b0;
@(posedge DUT.cpu_clk);
	force DUT.u_dm.dtm_req_valid = 1'b1;
	force DUT.u_dm.dtm_req_bits = {8'h0,1'b0,3'h0,1'b0,1'b0,1'b1,1'b1,16'h07a1,6'h17,2'b10};
@(posedge DUT.cpu_clk);
	force DUT.u_dm.dtm_req_valid = 1'b0;

	$display ("                                             \n");
	$display ("step3:  configure tdata2 for trigger0       \n");
@(posedge DUT.cpu_clk);
	force DUT.u_dm.dtm_req_valid = 1'b1;
	force DUT.u_dm.dtm_req_bits = {32'h0120,6'h04,2'b10};
@(posedge DUT.cpu_clk);
	force DUT.u_dm.dtm_req_valid = 1'b0;
@(posedge DUT.cpu_clk);
	force DUT.u_dm.dtm_req_valid = 1'b1;
	force DUT.u_dm.dtm_req_bits = {8'h0,1'b0,3'h0,1'b0,1'b0,1'b1,1'b1,16'h07a2,6'h17,2'b10};
@(posedge DUT.cpu_clk);
	force DUT.u_dm.dtm_req_valid = 1'b0;

end



wire test_end1;
assign test_end1 = DUT.u_core.u_dbg_mode_ctrl.breakpoint;

reg [31:0] break_pc;
reg [31:0] golden_value;

integer i;
integer fp_z;

initial
begin

	fp_z =$fopen ("./out/ref_values.txt","r");

@(posedge test_end1)
	break_pc = dec_pc;
	$display ("=============================================\n");
	$display ("TEST_END\n");
	$display ("the breakpoint is at %h\n",break_pc);

@(posedge DUT.cpu_clk);
@(posedge DUT.cpu_clk);
@(posedge DUT.cpu_clk);
@(posedge DUT.cpu_clk);

begin
	//check whether core is halted
	if(dec_pc == break_pc)
	begin
	$display ("=============================================\n");
	$display ("Core is halted after breakpoint met               \n");
	$display ("=============================================\n");
	end
	else
	begin
	$display ("=============================================\n");
	$display ("Core Failed to halted after ebreak met       \n");
	$display ("=============================================\n");
	end
	//check whether the GPRS has the same value as simulation breakpoint
	for (i=0; i<32; i=i+1)
	begin
		$fscanf(fp_z, "%h", golden_value);
		if(DUT.u_core.u_dec.u_gprs.gprs_X[i] == golden_value)
		$display ("GPRS%d compare PASS! ", i);
		else
		$display ("GPRS%d compare FAIL!\n GPRS%d = %h, golden_value = %h",i,i,DUT.u_core.u_dec.u_gprs.gprs_X[i],golden_value);
	end

	$fclose(fp_z);
	$stop;
end
end


