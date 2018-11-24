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

	input wire                   stallreq_from_id,

  //来自执行阶段的暂停请求
	input wire                   stallreq_from_ex,
	output reg[5:0]              stall       
	
);


	always @ (*) begin
		if(rst == `RstEnable) begin
			stall <= 6'b000000;
		end else if(stallreq_from_ex == `Stop) begin
			stall <= 6'b001111;
		end else if(stallreq_from_id == `Stop) begin
			stall <= 6'b000111;			
		end else begin
			stall <= 6'b000000;
		end    //if
	end      //always
endmodule
