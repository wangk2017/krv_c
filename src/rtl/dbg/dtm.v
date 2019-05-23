/*
 Licensed under the Apache License, Version 2.0 (the "License");         
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
// File Name: 		dtm.v					||
// Author:    		Kitty Wang				||
// Description: 						||
//	      		Debug Transport Module                  ||
// History:   		2019.05.12				||
//                      First version				||
//===============================================================
`include "dbg_defines"

module dtm(

//JTAG interface
input				TDI,
output reg			TDO,
input				TCK,
input				TMS,
input				TRST,

//dmi interface
input				sys_clk,
input				sys_rstn,

output				dtm_req_valid,
input				dtm_req_ready,
output[`DBUS_M_WIDTH - 1 : 0]	dtm_req_bits,

input				dm_resp_valid,
output				dm_resp_ready,
input[`DBUS_S_WIDTH - 1 : 0]	dm_resp_bits
);

//TAP controller

//TAP fsm
localparam TEST_LOGIC_RESET  = 4'h0;
localparam RUN_TEST_IDLE     = 4'h1;
localparam SELECT_DR         = 4'h2;
localparam CAPTURE_DR        = 4'h3;
localparam SHIFT_DR          = 4'h4;
localparam EXIT1_DR          = 4'h5;
localparam PAUSE_DR          = 4'h6;
localparam EXIT2_DR          = 4'h7;
localparam UPDATE_DR         = 4'h8;
localparam SELECT_IR         = 4'h9;
localparam CAPTURE_IR        = 4'hA;
localparam SHIFT_IR          = 4'hB;
localparam EXIT1_IR          = 4'hC;
localparam PAUSE_IR          = 4'hD;
localparam EXIT2_IR          = 4'hE;
localparam UPDATE_IR         = 4'hF;

//JTAG DTM TAP registers
localparam BYPASS       = 5'b11111;
localparam IDCODE       = 5'b00001;
localparam DMI_ACCESS   = 5'b10001;
localparam DTM_CS       = 5'b10000;


reg[3:0] tap_state, tap_next_state;

always @ (posedge TCK or posedge TRST)
begin
	if(TRST)
	begin
		tap_state <= TEST_LOGIC_RESET;
	end
	else
	begin
		tap_state <= tap_next_state;
	end
end

always @ *
begin
	case(tap_state)
	TEST_LOGIC_RESET : 
	begin
		if(TMS) tap_next_state = RUN_TEST_IDLE;
		else	tap_next_state = TEST_LOGIC_RESET;
	end
        RUN_TEST_IDLE    : 
	begin
		if(TMS) tap_next_state = SELECT_DR;
		else	tap_next_state = RUN_TEST_IDLE;
	end
        SELECT_DR        : 
	begin
		if(TMS) tap_next_state = SELECT_IR;
		else	tap_next_state = CAPTURE_DR;
	end
        CAPTURE_DR       : 
	begin
		if(TMS) tap_next_state =EXIT1_DR;
		else	tap_next_state = SHIFT_DR;
	end
        SHIFT_DR         : 
	begin
		if(TMS) tap_next_state = EXIT1_DR;
		else	tap_next_state = SHIFT_DR;
	end
        EXIT1_DR         : 
	begin
		if(TMS) tap_next_state = UPDATE_DR;
		else	tap_next_state = PAUSE_DR;
	end
        PAUSE_DR         : 
	begin
		if(TMS) tap_next_state = EXIT2_DR;
		else	tap_next_state = PAUSE_DR;
	end
        EXIT2_DR         : 
	begin
		if(TMS) tap_next_state = UPDATE_DR;
		else	tap_next_state = SHIFT_DR;
	end
        UPDATE_DR        : 
	begin
		if(TMS) tap_next_state = SELECT_DR;
		else	tap_next_state = RUN_TEST_IDLE;
	end
        SELECT_IR        : 
	begin
		if(TMS) tap_next_state = TEST_LOGIC_RESET;
		else	tap_next_state = CAPTURE_IR;
	end
        CAPTURE_IR       : 
	begin
		if(TMS) tap_next_state = EXIT1_IR;
		else	tap_next_state = SHIFT_IR;
	end
        SHIFT_IR         : 
	begin
		if(TMS) tap_next_state = EXIT1_IR;
		else	tap_next_state = SHIFT_IR;
	end
        EXIT1_IR         : 
	begin
		if(TMS) tap_next_state = UPDATE_IR;
		else	tap_next_state = PAUSE_IR;
	end
        PAUSE_IR         : 
	begin
		if(TMS) tap_next_state = EXIT2_IR;
		else	tap_next_state = PAUSE_IR;
	end
        EXIT2_IR         : 
	begin
		if(TMS) tap_next_state = UPDATE_IR;
		else	tap_next_state = SHIFT_IR;
	end
        UPDATE_IR        : 
	begin
		if(TMS) tap_next_state = SELECT_DR;
		else	tap_next_state = RUN_TEST_IDLE;
	end
	default: tap_next_state = TEST_LOGIC_RESET;
	endcase
end

reg [`DBUS_M_WIDTH - 1 : 0]		shift_reg;
reg [`IR_WIDTH - 1 : 0]			IR_reg;
reg [`DBUS_M_WIDTH - 1 : 0]		DR_reg;
reg					DR_reg_valid;

wire [`DBUS_M_WIDTH - 1 : 0]		dmi_read_data;
wire [`DBUS_M_WIDTH - 1 : 0]		dtm_cs_read_data;
wire [`DBUS_M_WIDTH - 1 : 0]		bypass_read_data;
wire [`DBUS_M_WIDTH - 1 : 0]		idcode_read_data;


//DMI access
wire [`DBUS_S_WIDTH - 1 : 0]	afifo_sysclk_2_TCK_read_data;
wire afifo_sysclk_2_TCK_read_data_valid;
wire [`DBUS_S_WIDTH - 1 : 0]	dmi_bits_sync = afifo_sysclk_2_TCK_read_data_valid ? afifo_sysclk_2_TCK_read_data : {`DBUS_S_WIDTH{1'b0}};

wire[1:0] dmi_op_read = dmi_bits_sync [`DBUS_OP_WIDTH - 1 : 0];

assign dmi_read_data = {DR_reg[(`DBUS_DATA_WIDTH + `DBUS_OP_WIDTH) +: `DBUS_ADDR_WIDTH],		//addr 
			dmi_bits_sync};		//dmi return data

//DTM contrl and status
wire dmireset = (IR_reg == DTM_CS) && (tap_state == UPDATE_DR) && shift_reg[16];

reg sticky_error;
wire afifo_TCK_2_sysclk_full;
wire afifo_TCK_2_sysclk_overflow = dmi_busy && DR_reg_valid;


always @ (posedge TCK or posedge TRST)
begin
	if(TRST)
	begin
		sticky_error <= 1'b0;
	end
	else
	begin
		if(dmireset)
		sticky_error <= 1'b0;
		else if(dmi_op_read[1] || afifo_TCK_2_sysclk_overflow)
		sticky_error <= 1'b1;
	end
end

wire dmi_busy = afifo_TCK_2_sysclk_full || sticky_error;

wire[2:0] dtm_idle = 5;
wire [1:0] dmi_state = {(dmi_op_read[1] || afifo_TCK_2_sysclk_overflow), afifo_TCK_2_sysclk_overflow};
wire [5:0] dtm_abits = 5;
wire [3:0] dtm_version = 0 ;

assign dtm_cs_read_data = {(`DBUS_M_WIDTH - 15){1'b0},
				dtm_idle,
				dmi_state,
				dtm_abits,
				dtm_version
				};


//BYPASS
assign bypass_read_data = {`DBUS_M_WIDTH{1'b0}};

//IDCODE
localparam VERSION	= 4'h0;
localparam PARTNUM	= 16'h0000;
localparam MANUFID	= 11'h000;

assign idcode = {`DBUS_M_WIDTH_MINUS_32{1'b0}, VERSION, PARTNUM, MANUFID,1'b1};



//shift reg
always @ (posedge TCK or posedge TRST)
begin
	if(TRST)
	begin
		shift_reg <= {`DBUS_M_WIDTH{1'b0}};
	end
	else	
	begin
		case(tap_state)
		CAPTURE_DR:
		begin
			case (IR_reg)
			BYPASS		:	shift_reg <= bypass_read_data;    
                        IDCODE    	:	shift_reg <= idcode_read_data;
                        DMI_ACCESS	:	shift_reg <= dmi_read_data;
                        DTM_CS    	:	shift_reg <= dtm_cs_read_data;
			default		:	shift_reg <= bypass_read_data;
			endcase
		end
		SHIFT_DR,SHIFT_IF:	shift_reg <= {TDI, shift_reg[`DBUS_M_WIDTH - 1 : 1]};
		CAPTURE_IR:		shift_reg <= {`DBUS_M_WIDTH_MINUS_1{1'b0},1'b1};
		default: 		shift_reg <= {`DBUS_M_WIDTH{1'b0}};
		endcase
	end
end

//IR_reg
always @ (posedge TCK or posedge TRST)
begin
	if(TRST)
	begin
		IR_reg <= IDCODE;
	end
	else
	begin
		if(tap_state == TEST_LOGIC_RESET)
		IR_reg <= IDCODE;
		else if(tap_state == UPDATE_IR)
		IR_reg <= shift_reg[`IR_WIDTH - 1 : 0];
	end
end

//DR_reg
always @ (posedge TCK or posedge TRST)
begin
	if(TRST)
	begin
		DR_reg <= {`DBUS_M_WIDTH{1'b0}};
	end
	else
	begin
		if(tap_state == UPDATE_DR)
		DR_reg <= shift_reg;
	end
end

always @ (posedge TCK or posedge TRST)
begin
	if(TRST)
	begin
		DR_reg_valid <= 1'b0;
	end
	else
	begin
		if(tap_state == UPDATE_DR)
		DR_reg_valid <= 1'b1;
		else
		DR_reg_valid <= 1'b0;
	end
end

//JTAG TDO
always @ (posedge TCK or posedge TRST)
begin
	if(TRST)
	begin
		TDO <= 1'b0;
	end
	else
	begin
		if((tap_state == SHIFT_DR) || (tap_state == SHIFT_IR)) 
		TDO <= shift_reg[0];
		else
		TDO <= 1'b0;
	end
end


//CDC between JTAG TCK domain and debug module clk domain
//async fifo from TCK to system clock
async_fifo #(.DATA_WIDTH(`DBUS_M_WIDTH), .FIFO_DEPTH(2),.PTR_WIDTH(1)) 
afifo_TCK_2_sysclk(
.wr_clk		(TCK),
.wr_rstn	(!TRST),
.wr_valid	(DR_reg_valid),
.wr_data	(DR_reg),
.rd_clk		(sys_clk),
.rd_rstn	(sys_rstn),
.rd_ready	(dtm_req_ready),
.rd_valid	(dtm_req_valid),
.rd_data	(dtm_req_bits),
.full		(afifo_TCK_2_sysclk_full),
.empty		()
);

//async fifo from system clock to TCK
wire dmt_read_ready = (tap_state ==CAPTURE_DR);
wire afifo_sysclk_2_TCK_full;
async_fifo #(.DATA_WIDTH(`DBUS_S_WIDTH), .FIFO_DEPTH(2),.PTR_WIDTH(1)) 
afifo_sysclk_2_TCK(
.wr_clk		(sys_clk),
.wr_rstn	(sys_rstn),
.wr_valid	(dm_resp_valid),
.wr_data	(dm_resp_bits),
.rd_clk		(TCK),
.rd_rstn	(!TRST),
.rd_ready	(dmt_read_ready),
.rd_valid	(afifo_sysclk_2_TCK_read_data_valid),
.rd_data	(afifo_sysclk_2_TCK_read_data),
.full		(afifo_sysclk_2_TCK_full),
.empty		()
);

assign dm_resp_ready = !afifo_sysclk_2_TCK_full;


endmodule
