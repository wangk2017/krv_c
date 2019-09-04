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
assign test_end1 = dec_pc == 32'h00000d00;

integer fp_z;

initial
begin
	$display ("=============================================\n");
	$display ("running Zephyr OS application hello world\n");
	$display ("=============================================\n");

	fp_z =$fopen ("./out/uart_tx_data.txt","w");
@(posedge test_end1)
@(posedge DUT.cpu_clk);
begin
	$fclose(fp_z);
	$display ("=============================================\n");
	$display ("TEST_END\n");
	$display ("The application Print data is stored in \n");
	$display ("out/uart_tx_data.txt\n");
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
parameter MAIN 			= 32'h000003c8;
parameter SWAP			= 32'h00000228;
parameter BG_THREAD_MAIN	= 32'h000013a8;

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
		SWAP:// <__swap>
		begin
			$display ("swap Start");
			$display ("@time %t  !",$time);
			$display ("\n");
		end
		BG_THREAD_MAIN: //<bg_thread_main>
		begin
			$display ("bg_thread_main Start");
			$display ("@time %t  !",$time);
			$display ("\n");
		end
	endcase
end

wire [31:0] mem_addr = DUT.u_core.u_dmem_ctrl.mem_addr_mem;
wire [31:0] mem_wr_data = DUT.u_core.u_dmem_ctrl.store_data_mem;
wire mem_wr = DUT.u_core.u_dmem_ctrl.store_mem;
always @(posedge DUT.cpu_clk)
begin
	if(mem_wr && (mem_addr == 32'h40014))
		begin
			$display ("write 40014");
			$display ("@time %t  !",$time);
			$display ("\n");
		end
end
