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

module dtm(

//JTAG interface
input				TDI,
output reg			TDO,
input				TCK,
input				TMS,
input				TRST,

//dmi interface
output				dtm_valid,
input				dmi_ready,
output[`DBUS_M_WIDTH - 1 : 0]	dtm_bits,

input				dmi_valid,
output				dtm_ready,
input[`DBUS_S_WIDTH - 1 : 0]	dmi_bits
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

//TODO
//CDC between JTAG TCK domain and debug module clk domain

//DMI access
wire [`DBUS_S_WIDTH - 1 : 0]	dmi_bits_sync;

assign dmi_read_data = {DR_reg[(`DBUS_DATA_WIDTH + `DBUS_OP_WIDTH) +: `DBUS_ADDR_WIDTH],		//addr 
			dmi_bits_sync};		//dmi return data

//TODO
//DTM contrl and status
assign dtm_cs_read_data = {};

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
		DR_reg <= 1'b1;
		else if(dmi_ready_sync)
		DR_reg <= 1'b0;
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


endmodule
