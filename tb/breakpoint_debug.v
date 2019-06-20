`include "dbg_tasks.v"
`include "dbg_defines.vh"
//configure breakpoint by debugger (with a dtm driver)
initial
begin
	force DUT.u_dm.dtm_req_valid = 1'b0;

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
	$display ("---------------------------------------------\n");

	dtm_write_reg(32'h0,`DATA0_ADDR);
	dtm_write_reg({8'h0,1'b0,3'h0,1'b0,1'b0,1'b1,1'b1,16'h07a0},`COMMAND_ADDR);

	$display ("                                            \n");
	$display ("step2:  configure tdata1 for trigger0       \n");
	dtm_write_reg({4'h2,1'b1,6'h0,1'b0,1'b0,1'b0,2'h0,4'h1,1'b0,4'h0,1'b1,3'h0,1'b1,2'h0},`DATA0_ADDR);
	dtm_write_reg({8'h0,1'b0,3'h0,1'b0,1'b0,1'b1,1'b1,16'h07a1},`COMMAND_ADDR);

	$display ("                                             \n");
	$display ("step3:  configure tdata2 for trigger0       \n");
	dtm_write_reg(32'h0120,`DATA0_ADDR);
	dtm_write_reg({8'h0,1'b0,3'h0,1'b0,1'b0,1'b1,1'b1,16'h07a2},`COMMAND_ADDR);

end



wire test_end1;
assign test_end1 = DUT.u_core.u_dbg_mode_ctrl.breakpoint;

reg [31:0] break_pc;
reg [31:0] golden_value;

reg[7:0] i;
reg[7:0] j;
integer fp_z;
integer fp_m;
integer fp_w;

initial
begin
force DUT.u_dm.dm_resp_ready = 1'b1;

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
	$display ("Core Failed to halted after breakpoint       \n");
	$display ("=============================================\n");
	end
	//check whether the GPRS has the same value as simulation breakpoint
	$display ("=============================================\n");
	$display ("check the GPRS value                        \n");
	$display ("=============================================\n");
	for (i=0; i<32; i=i+1)
	begin
		$fscanf(fp_z, "%h", golden_value);
		if(DUT.u_core.u_dec.u_gprs.gprs_X[i] == golden_value)
		$display ("GPRS%d compare PASS! ", i);
		else
		$display ("GPRS%d compare FAIL!\n GPRS%d = %h, golden_value = %h",i,i,DUT.u_core.u_dec.u_gprs.gprs_X[i],golden_value);
	end
	$fclose(fp_z);

@(posedge DUT.cpu_clk);
@(posedge DUT.cpu_clk);
@(posedge DUT.cpu_clk);
	$display ("=============================================\n");
	$display ("check DM access GPRS after breakpoint       \n");
	$display ("=============================================\n");

	fp_z =$fopen ("./out/ref_values.txt","r");
	for (j=0; j<32; j=j+1)
	begin
		$display ("-----------------------------------------\n");
		$display ("debugger send abs command to read GPRS %d\n",j);
		dtm_write_reg({8'h0,1'b0,3'h0,1'b0,1'b0,1'b1,1'b0,8'h10,j},`COMMAND_ADDR);

		$display ("debugger read the return value from data0\n");
		dtm_read_reg(`DATA0_ADDR);

		@(posedge DUT.u_dm.u_dm_regs.dm_resp_valid);
		begin
			$fscanf(fp_z, "%h", golden_value);
			if(DUT.u_dm.u_dm_regs.dm_resp_bits[31:0] == golden_value)
			begin
			$display ("GPRS%d compare PASS! \n", j);
			$display ("-----------------------------------------\n");
			end
			else
			begin
			$display ("GPRS%d compare FAIL!\nGPRS%d = %h, golden_value = %h \n",j,j,DUT.u_dm.u_dm_regs.dm_resp_bits[31:0],golden_value);
			$display ("-----------------------------------------\n");
			end
		end
	end
	$fclose(fp_z);
//check memory read by system_bus_access
	$display ("=============================================\n");
	$display ("check DM read memory after breakpoint       \n");
	$display ("=============================================\n");
		$display ("----------------------------------------------------------------\n");
		$display ("debugger configure the system access control and status register\n");
		dtm_write_reg({3'h0,6'h0,1'b0,1'b0,1'b1,3'h2,1'b0,1'b0,3'h0,7'h0,5'h0},`SBCS_ADDR);

	fp_m =$fopen ("./out/ref_mem_values.txt","r");
	for (j=32; j<48; j=j+1)
	begin
		$display ("----------------------------------------------------------------\n");
		$display ("debugger write the read address to system bus address 32:0\n");
		dtm_write_reg(j*4,`SBADDR0_ADDR);


@(posedge DUT.cpu_clk);
@(posedge DUT.cpu_clk);
@(posedge DUT.cpu_clk);

		$display ("debugger read the return value from sbdata0\n");
		dtm_read_reg(`SBDATA0_ADDR);

		@(posedge DUT.u_dm.u_dm_regs.dm_resp_valid);
		begin
			$fscanf(fp_m, "%h", golden_value);
			if(DUT.u_dm.u_dm_regs.dm_resp_bits[31:0] == golden_value)
			begin
			$display ("mem[%h] compare PASS! \n", j*4);
			$display ("-----------------------------------------\n");
			end
			else
			begin
			$display ("mem[%h] compare FAIL!\nmem[%h] = %h, golden_value = %h \n",j*4,j*4,DUT.u_dm.u_dm_regs.dm_resp_bits[31:0],golden_value);
			$display ("-----------------------------------------\n");
			end
		end
	end
$fclose(fp_z);

//check memory write by system_bus_access
	$display ("=============================================\n");
	$display ("check DM write itcm                        	\n");
	$display ("=============================================\n");
	fp_w =$fopen ("./tb/dbg_test_value.txt","r");
	for (j=48; j<64; j=j+1)
	begin
		$fscanf(fp_w, "%h", golden_value);
		$display ("----------------------------------------------------------------\n");
		$display ("debugger write the address to system bus address 32:0\n");
		dtm_write_reg(j*4,`SBADDR0_ADDR);
		$display ("debugger write the value to sbdata0\n");
		dtm_write_reg(golden_value, `SBDATA0_ADDR);
		@(posedge DUT.cpu_clk);
		@(posedge DUT.cpu_clk);
		@(posedge DUT.cpu_clk);
		$display ("debugger read on SBADDR0 update\n");
		dtm_write_reg(j*4,`SBADDR0_ADDR);
		@(posedge DUT.cpu_clk);
		@(posedge DUT.cpu_clk);
		@(posedge DUT.cpu_clk);
		$display ("debugger read the return value from sbdata0\n");
		dtm_read_reg(`SBDATA0_ADDR);

		@(posedge DUT.u_dm.u_dm_regs.dm_resp_valid);
		begin
			if(DUT.u_dm.u_dm_regs.dm_resp_bits[31:0] == golden_value)
			begin
			$display ("mem[%h] compare PASS! \n", j*4);
			$display ("-----------------------------------------\n");
			end
			else
			begin
			$display ("mem[%h] compare FAIL!\nmem[%h] = %h, golden_value = %h \n",j*4,j*4,DUT.u_dm.u_dm_regs.dm_resp_bits[31:0],golden_value);
			$display ("-----------------------------------------\n");
			end
		end
	end
	$fclose(fp_w);

	$display ("=============================================\n");
	$display ("check DM write dtcm                        	\n");
	$display ("=============================================\n");
	fp_w =$fopen ("./tb/dbg_test_value.txt","r");
	for (j=0; j<16; j=j+1)
	begin
		$fscanf(fp_w, "%h", golden_value);
		$display ("----------------------------------------------------------------\n");
		$display ("debugger write the address to system bus address 32:0\n");
		dtm_write_reg(32'h40000 + j*4,`SBADDR0_ADDR);
		$display ("debugger write the value to sbdata0\n");
		dtm_write_reg(golden_value, `SBDATA0_ADDR);
		@(posedge DUT.cpu_clk);
		@(posedge DUT.cpu_clk);
		@(posedge DUT.cpu_clk);
		$display ("debugger read on SBADDR0 update\n");
		dtm_write_reg(32'h40000 + j*4,`SBADDR0_ADDR);
		@(posedge DUT.cpu_clk);
		@(posedge DUT.cpu_clk);
		@(posedge DUT.cpu_clk);
		$display ("debugger read the return value from sbdata0\n");
		dtm_read_reg(`SBDATA0_ADDR);

		@(posedge DUT.u_dm.u_dm_regs.dm_resp_valid);
		begin
			if(DUT.u_dm.u_dm_regs.dm_resp_bits[31:0] == golden_value)
			begin
			$display ("mem[%h] compare PASS! \n", 32'h40000 + j*4);
			$display ("-----------------------------------------\n");
			end
			else
			begin
			$display ("mem[%h] compare FAIL!\nmem[%h] = %h, golden_value = %h \n",32'h40000 + j*4,j*4,DUT.u_dm.u_dm_regs.dm_resp_bits[31:0],golden_value);
			$display ("-----------------------------------------\n");
			end
		end
	end
	$fclose(fp_w);


	$stop;
end
end


