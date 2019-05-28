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
// File Name: 		hw_triggers.v				||
// Author:    		Kitty Wang				||
// Description: 						||
//	      		hardware trigger module                 ||
// History:   							||
//                      2019/5/27 				||
//                      First version				||
//===============================================================

`include "core_defines.vh"
`include "dbg_defines.vh"

module hw_triggers (
//global signals
input wire cpu_clk,					//cpu clock
input wire cpu_rstn,					//cpu reset, active low

//trigger regs
input tselect,
input [`DATA_WIDTH - 1 : 0] tdata1,
input [`DATA_WIDTH - 1 : 0] tdata2_t0,
input [`DATA_WIDTH - 1 : 0] tdata2_t1,
input [`DATA_WIDTH - 1 : 0] tdata3_t0,
input [`DATA_WIDTH - 1 : 0] tdata3_t1,
output[`DATA_WIDTH - 1 : 0] mctrl_rd_data, 
//trigger sources
input [`ADDR_WIDTH - 1 : 0] pc_ex,
input load_ex,
input store_ex,
input [`ADDR_WIDTH - 1 : 0] mem_addr_ex


output reg breakpoint,		//enter debug mode
output reg breakpoint_exp,	//just a breakpoint exception

);


//tdata1 decode
wire type = tdata1[`DATA_WIDTH - 1 : `DATA_WIDTH -4];
wire dmode = tdata1[`DATA_WIDTH - 5];

//mcontrol when tdata1.type == 2

wire mctrl_type = (type == 2);

wire [5:0] maskmax = mctrl_type ? tdata1[`DATA_WIDTH - 6 : `DATA_WIDTH - 11] : 6'h0;
wire select = 1'b0;
wire timing = mctrl_type ? tdata1[18] : 1'b0;
wire [1:0] sizelo = mctrl_type ? tdata1[17:16] : 2'h0;
wire [3:0] action = mctrl_type ? tdata1[15:12] : 4'h0;
wire chain = mctrl_type ? tdata1[11] : 1'h0;
wire [3:0] match = mctrl_type ? tdata1[10:7] : 4'h0;
wire m_prv = mctrl_type ? tdata1[6] : 1'h0;
wire execute = mctrl_type ? tdata1[2] : 1'h0;
wire store = mctrl_type ? tdata1[1] : 1'h0;
wire load = mctrl_type ? tdata1[0] : 1'h0;

assign mctrl_rd_data = {type,dmode,maskmax,1'b0,select,timing,sizelo,action,chain,match,m_prv,3'b0,execute,store,load};


wire trigger_type = {execute,store,load};
//trigger0
reg trigger0;

always @ *
begin
	if(!tselect && m_prv)	//select trigger0 at M priviledge
	begin
		case {trigger_type)
		3'b001: begin			//load
			if(load_mem && (mem_addr_mem == tdata2_t0))
			trigger0 = 1'b1;
			else
			trigger0 = 1'b0;
		end
		3'b010: begin			//store
			if(store_mem && (mem_addr_mem == tdata2_t0))
			trigger0 = 1'b1;
			else
			trigger0 = 1'b0;
		end
		3'b100: begin			//pc
			if(pc_ex == tdata2_t0)
			trigger0 = 1'b1;
			else
			trigger0 = 1'b0;
		end
		default: trigger0 = 1'b0;
		endcase
	end
end


//trigger1
reg trigger1;

always @ *
begin
	if(!tselect && m_prv)	//select trigger1 at M priviledge
	begin
		case {trigger_type)
		3'b001: begin			//load
			if(load_mem && (mem_addr_mem == tdata2_t1))
			trigger1 = 1'b1;
			else
			trigger1 = 1'b0;
		end
		3'b010: begin			//store
			if(store_mem && (mem_addr_mem == tdata2_t1))
			trigger1 = 1'b1;
			else
			trigger1 = 1'b0;
		end
		3'b100: begin			//pc
			if(pc_ex == tdata2_t1)
			trigger1 = 1'b1;
			else
			trigger1 = 1'b0;
		end
		default: trigger1 = 1'b0;
		endcase
	end
end

//action with the trigger
wire trigger = trigger0 || (trigger1 && ((chain && trigger0) || !chain));
//breakpoint

always @ (posedge cpu_clk or negedge cpu_rstn)
begin
	if(!cpu_rstn)
	begin
		breakpoint <= 1'b0;
	end
	else
	begin
		if(dmode && trigger && action && !dbg_mode)
		breakpoint <= 1'b1;
		else
		breakpoint <= 1'b0;
	end
end

//breakpoint_exception

always @ (posedge cpu_clk or negedge cpu_rstn)
begin
	if(!cpu_rstn)
	begin
		breakpoint_exp <= 1'b0;
	end
	else
	begin
		if(trigger && !action && !dbg_mode)
		breakpoint_exp <= 1'b1;
		else
		breakpoint_exp <= 1'b0;
	end
end



endmodule
