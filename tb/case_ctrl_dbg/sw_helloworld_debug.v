wire uart_tx_wr = DUT.m_apb.uart_0.tx_data_reg_wr;
wire[7:0] uart_tx_data = DUT.m_apb.uart_0.tx_data;

//Play a trick to let the simulation run faster

initial
begin
#5;
$display ("=========================================================================== \n");
$display ("Here is a trick to force the baud rate higher to make the simulation faster \n");
$display ("you can turn off the trick in tb/zephyr_debug.v by comment the force \n");
$display ("=========================================================================== \n");
force DUT.m_apb.uart_0.uart_0.baud_val = 13'h4;
end



wire test_end1;
assign test_end1 = dec_pc == 32'h0000007c;

integer fp_z;

initial
begin
	$display ("=============================================\n");
	$display ("running SW application hello world\n");
	$display ("=============================================\n");

	fp_z =$fopen ("./out/sw_helloworld.txt","w");
@(posedge test_end1)
@(posedge DUT.cpu_clk);
begin
	$fclose(fp_z);
	$display ("=============================================\n");
	$display ("TEST_END\n");
	$display ("The application Print data is stored in \n");
	$display ("out/sw_helloworld.txt\n");
	$display ("=============================================\n");
	$stop;
end
end

always @(posedge DUT.cpu_clk)
begin
	if(uart_tx_wr)
		begin
			$fwrite(fp_z, "%s", uart_tx_data);
			$display ("UART Transmitt DATA is %s ",uart_tx_data);
			$display ("\n");
		end

end
parameter MAIN 			= 32'h00000084;

//application process trace during simulation
always @(posedge DUT.cpu_clk)
begin
		case (dec_pc)
		MAIN:	//main
		begin
			$display ("Main Start");
			$display ("@time %t  !",$time);
			$display ("\n");
		end
		endcase
end


