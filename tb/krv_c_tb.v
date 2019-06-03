`include "top_defines.vh"
`include "tb_defines.vh"
`timescale 1ns/100ps

module krv_c_TB ();

reg clk_in;
reg porn;
wire UART_TX;
wire [7:0] GPIO_OUT;

krv_c DUT (
	.clk_in			(clk_in),
	.porn			(porn),
	.UART_TX		(UART_TX),
	.UART_RX		(1'b1),
	.GPIO_IN		(8'h0),
	.GPIO_OUT		(GPIO_OUT)
);

//clocks

	always 
	begin
	#20 clk_in <= ~clk_in;
	end
	
wire [31:0] dec_pc = DUT.u_core.u_fetch.pc_dec;

`ifdef PG_TEST
`include "pg_sr.v"
`endif

`ifdef DHRYSTONE
`include "dhrystone_debug.v"
`endif

`ifdef ZEPHYR
`include "zephyr_debug.v"
`endif

`ifdef TESTN
`include "testn_debug.v"
`endif

`ifdef ZEPHYR_PHIL
`include "zephyr_phil_debug.v"
`endif

`ifdef ZEPHYR_SYNC
`include "zephyr_sync_debug.v"
`endif

`ifdef DBG_REF
`include "dbg_ref_value.v"
`endif

`ifdef BREAKPOINT
`include "break_debug.v"
`endif

wire test_end;
`ifdef RISCV
assign test_end = (dec_pc == 32'h48);
`else
assign test_end = 0; 
`endif


initial 
begin

	clk_in <= 0;
	porn <= 0;
	$readmemh("./hex_file/run.hex",DUT.u_flash_ss.mem);

	@(posedge clk_in);
	porn <=1;
	
	@(posedge test_end)
	begin
		@(posedge DUT.cpu_clk);
		$display ("||===========================================||");
		$display ("||===========================================||");
		$display ("||               TEST END                    ||");
		$display ("||===========================================||");
		$display ("||                                           ||");
		$display ("||===========================================||");
		$display ("||               TEST RESULT:                ||");
		$display ("||===========================================||");
		$display ("||===========================================||");
			if (DUT.u_core.u_dec.u_gprs.gprs_X[3] == 1)
			begin
				$display ("||===========================================||");
				$display ("||                                           ||");
				$display ("||            PC stops @ %x            ||",dec_pc);
				$display ("||                                           ||");
				$display ("||                  Run Pass !               ||");
				$display ("||                                           ||");
				$display ("||===========================================||");
			end
			else
			begin
				$display ("||===========================================||");
				$display ("||                                           ||");
				$display ("||                  Ooops......              ||");
				$display ("||                  Run Fail !               ||");
				$display ("||                                           ||");
				$display ("||===========================================||");
			end
		$stop;
	end
end

initial
begin
`ifndef RISCV
	repeat (1000000)
`else
	repeat (80000)
`endif
	begin
	@(posedge DUT.cpu_clk);
	end
	$display (" ||===================================||");
	$display (" ||===================================||");
	$display (" ||                                   ||");
	$display (" ||             Time Out!             ||");
	$display (" ||                                   ||");
	$display (" ||===================================||");
	$display (" ||===================================||");
	$stop;

end

initial
begin
$dumpfile("./out/krv.vcd");
$dumpvars(0, krv_c_TB);
end

//signals for debug
wire [`DATA_WIDTH - 1 : 0] gprs_0  = DUT.u_core.u_dec.u_gprs.gprs_X[0];
wire [`DATA_WIDTH - 1 : 0] gprs_1  = DUT.u_core.u_dec.u_gprs.gprs_X[1];
wire [`DATA_WIDTH - 1 : 0] gprs_2  = DUT.u_core.u_dec.u_gprs.gprs_X[2];
wire [`DATA_WIDTH - 1 : 0] gprs_3  = DUT.u_core.u_dec.u_gprs.gprs_X[3];
wire [`DATA_WIDTH - 1 : 0] gprs_4  = DUT.u_core.u_dec.u_gprs.gprs_X[4];
wire [`DATA_WIDTH - 1 : 0] gprs_5  = DUT.u_core.u_dec.u_gprs.gprs_X[5];
wire [`DATA_WIDTH - 1 : 0] gprs_6  = DUT.u_core.u_dec.u_gprs.gprs_X[6];
wire [`DATA_WIDTH - 1 : 0] gprs_7  = DUT.u_core.u_dec.u_gprs.gprs_X[7];
wire [`DATA_WIDTH - 1 : 0] gprs_8  = DUT.u_core.u_dec.u_gprs.gprs_X[8];
wire [`DATA_WIDTH - 1 : 0] gprs_9  = DUT.u_core.u_dec.u_gprs.gprs_X[9];
wire [`DATA_WIDTH - 1 : 0] gprs_10 = DUT.u_core.u_dec.u_gprs.gprs_X[10];
wire [`DATA_WIDTH - 1 : 0] gprs_11 = DUT.u_core.u_dec.u_gprs.gprs_X[11];
wire [`DATA_WIDTH - 1 : 0] gprs_12 = DUT.u_core.u_dec.u_gprs.gprs_X[12];
wire [`DATA_WIDTH - 1 : 0] gprs_13 = DUT.u_core.u_dec.u_gprs.gprs_X[13];
wire [`DATA_WIDTH - 1 : 0] gprs_14 = DUT.u_core.u_dec.u_gprs.gprs_X[14];
wire [`DATA_WIDTH - 1 : 0] gprs_15 = DUT.u_core.u_dec.u_gprs.gprs_X[15];
wire [`DATA_WIDTH - 1 : 0] gprs_16 = DUT.u_core.u_dec.u_gprs.gprs_X[16];
wire [`DATA_WIDTH - 1 : 0] gprs_17 = DUT.u_core.u_dec.u_gprs.gprs_X[17];
wire [`DATA_WIDTH - 1 : 0] gprs_18 = DUT.u_core.u_dec.u_gprs.gprs_X[18];
wire [`DATA_WIDTH - 1 : 0] gprs_19 = DUT.u_core.u_dec.u_gprs.gprs_X[19];
wire [`DATA_WIDTH - 1 : 0] gprs_20 = DUT.u_core.u_dec.u_gprs.gprs_X[20];
wire [`DATA_WIDTH - 1 : 0] gprs_21 = DUT.u_core.u_dec.u_gprs.gprs_X[21];
wire [`DATA_WIDTH - 1 : 0] gprs_22 = DUT.u_core.u_dec.u_gprs.gprs_X[22];
wire [`DATA_WIDTH - 1 : 0] gprs_23 = DUT.u_core.u_dec.u_gprs.gprs_X[23];
wire [`DATA_WIDTH - 1 : 0] gprs_24 = DUT.u_core.u_dec.u_gprs.gprs_X[24];
wire [`DATA_WIDTH - 1 : 0] gprs_25 = DUT.u_core.u_dec.u_gprs.gprs_X[25];
wire [`DATA_WIDTH - 1 : 0] gprs_26 = DUT.u_core.u_dec.u_gprs.gprs_X[26];
wire [`DATA_WIDTH - 1 : 0] gprs_27 = DUT.u_core.u_dec.u_gprs.gprs_X[27];
wire [`DATA_WIDTH - 1 : 0] gprs_28 = DUT.u_core.u_dec.u_gprs.gprs_X[28];
wire [`DATA_WIDTH - 1 : 0] gprs_29 = DUT.u_core.u_dec.u_gprs.gprs_X[29];
wire [`DATA_WIDTH - 1 : 0] gprs_30 = DUT.u_core.u_dec.u_gprs.gprs_X[30];
wire [`DATA_WIDTH - 1 : 0] gprs_31 = DUT.u_core.u_dec.u_gprs.gprs_X[31];


endmodule

