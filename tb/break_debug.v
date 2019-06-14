
wire test_end1;
assign test_end1 = DUT.u_core.u_dec.ebreak;

reg [31:0] break_pc;
reg [31:0] golden_value;

integer i;
integer fp_z;

initial
begin
	force DUT.u_dm.dtm_req_valid = 1'b0;

	$display ("=============================================\n");
	$display ("running test to debug ebreak/breakpoint\n");
	$display ("=============================================\n");

	fp_z =$fopen ("./out/ref_values.txt","r");

@(posedge test_end1)
	break_pc = dec_pc;
	$display ("=============================================\n");
	$display ("TEST_END\n");
	$display ("the breakpoint is at %h\n",dec_pc);

@(posedge DUT.cpu_clk);
@(posedge DUT.cpu_clk);
@(posedge DUT.cpu_clk);
@(posedge DUT.cpu_clk);

begin
	//check whether core is halted
	if(dec_pc == break_pc)
	begin
	$display ("=============================================\n");
	$display ("Core is halted after ebreak met               \n");
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


