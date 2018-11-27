//////////////////////////////////////////////////////////////////////
// Module:  ctrl
// File:    ctrl.v
// Author:  BaiReny
// E-mail:  bry6789@163.com
// Description: 控制模块，控制流水线的刷新、暂停等
// Revision: 1.0
//////////////////////////////////////////////////////////////////////

`include "defines.vh"

module ctrl(

	input wire										rst,

	input wire                  stallreq_from_id,
	input wire                  stallreq_from_ex,
	input wire					stallreq_from_if,
	input wire                 stallreq_from_mem,
	output reg[5:0]             stall,      
	output wire[`DebugBus]      debugdata  
);
    assign debugdata = {3'b0,stallreq_from_id,3'b0,stallreq_from_ex,10'b0,stall[5:0]};

	always @ (*) begin
		if(rst == `RstEnable) begin
			stall <= 6'b000000;
		end else if (stallreq_from_mem == `Stop) begin
        	stall <= 6'b011111;	
		end else if(stallreq_from_ex == `Stop) begin
			stall <= 6'b001111;
		end else if(stallreq_from_id == `Stop) begin
			stall <= 6'b000111;	
        end else if (stallreq_from_if == `Stop) begin
        	stall <= 6'b000111;
		end else begin
			stall <= 6'b000000;
		end    //if
	end      //always
endmodule
