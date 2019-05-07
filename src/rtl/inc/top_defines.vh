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
`include "user_config.vh"
`include "core_defines.vh"
`include "kplic_defines.vh"
`include "ahb_defines.vh"

//Global defines
`define SYNC_HCLK 1
`define VECTOR_ENTRY 30'h0000_0000

//power gating
//`define THRESHOLD_ENTER_DEEP_SLEEP 40'hFF_FFFF_FFFF
//FIXME used for test
`define THRESHOLD_ENTER_DEEP_SLEEP 40'h00_0000_000F
`define SAVE_PERIOD	2'h1
`define PG_RESET_PERIOD	3'h3
`define RESTORE_PERIOD	2'h1
`define MOTHER_SLEEP_PERIOD	2'h1
`define MOTHER_WAKE_PERIOD	2'h1


