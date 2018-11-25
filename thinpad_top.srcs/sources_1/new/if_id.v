//////////////////////////////////////////////////////////////////////
// Module:  if_id
// File:    if_id.v
// Author:  BaiReny
// E-mail:  bry6789@163.com
// Description: IF/ID½×¶ÎµÄ¼Ä´æÆ÷
// Revision: 1.0
//////////////////////////////////////////////////////////////////////

`include "defines.vh"

module if_id(

	input	wire										clk,
	input wire										rst,
	

	input wire[`InstAddrBus]	   if_pc,
	input wire[`InstBus]          if_inst,
	output reg[`InstAddrBus]      id_pc,
	output reg[`InstBus]          id_inst,  
	input wire[5:0]               stall,
	output wire[`DebugBus] debugdata
 );
    assign debugdata = {if_pc[7:0],if_inst[15:0]};

	always @ (posedge clk) begin
		if (rst == `RstEnable) begin
            id_pc <= `ZeroWord;
            id_inst <= `ZeroWord;
        end else if(stall[1] == `Stop && stall[2] == `NoStop) begin
            id_pc <= `ZeroWord;
            id_inst <= `ZeroWord;    
        end else if(stall[1] == `NoStop) begin
            id_pc <= if_pc;
            id_inst <= if_inst;
        end
    end

endmodule