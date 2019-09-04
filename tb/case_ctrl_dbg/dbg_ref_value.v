
wire test_end1;
assign test_end1 = dec_pc == 32'h00000120;

integer i;
integer fp_z;
integer fp_m;

initial
begin
	$display ("=============================================\n");
	$display ("running test to get debug reference values\n");
	$display ("=============================================\n");

	fp_z =$fopen ("./out/ref_values.txt","w");
	fp_m =$fopen ("./out/ref_mem_values.txt","w");
@(posedge test_end1)
	$display ("=============================================\n");
	$display ("TEST_END\n");
	$display ("the breakpoint is at %h\n",dec_pc);
@(posedge DUT.cpu_clk);
@(posedge DUT.cpu_clk);
@(posedge DUT.cpu_clk);
@(posedge DUT.cpu_clk);
begin
	for (i=0; i<32; i=i+1)
	begin
		$fwrite(fp_z, "%h \n", DUT.u_core.u_dec.u_gprs.gprs_X[i]);
	end
	$fclose(fp_z);
	//
	for(i=32; i<48; i=i+1)
	begin
		$fwrite(fp_m, "%h \n", DUT.u_itcm.itcm[i]);
	end
	$display ("The reference register values stored in \n");
	$display ("out/ref_values.txt\n");
	$display ("The reference memory values stored in \n");
	$display ("out/ref_mem_values.txt\n");
	$display ("=============================================\n");
	$stop;
end
end


