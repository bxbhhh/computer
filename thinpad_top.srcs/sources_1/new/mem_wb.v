//////////////////////////////////////////////////////////////////////
// Module:  mem_wb
// File:    mem_wb.v
// Author:  BaiReny
// E-mail:  bry6789@163.com
// Description: MEM/WB�׶εļĴ���
// Revision: 1.0
//////////////////////////////////////////////////////////////////////

`include "defines.vh"

module mem_wb(

	input	wire		clk,
	input wire			rst,
	input wire[5:0]    stall,
	

	//���Էô�׶ε���Ϣ	
	input wire[`RegAddrBus]       mem_wd,
	input wire                    mem_wreg,
	input wire[`RegBus]					 mem_wdata,

	//�͵���д�׶ε���Ϣ
	output reg[`RegAddrBus]      wb_wd,
	output reg                   wb_wreg,
	output reg[`RegBus]					 wb_wdata,	       
	output wire[`DebugBus]        debugdata       
);
    assign debugdata = {3'b0,mem_wd[4:0],mem_wdata[15:0]};


	always @ (posedge clk) begin
		if(rst == `RstEnable) begin
			wb_wd <= `NOPRegAddr;
			wb_wreg <= `WriteDisable;
		  wb_wdata <= `ZeroWord;
		end else if(stall[4] == `Stop && stall[5] == `NoStop) begin
              wb_wd <= `NOPRegAddr;
              wb_wreg <= `WriteDisable;
              wb_wdata <= `ZeroWord;		  	
		end else begin
			wb_wd <= mem_wd;
			wb_wreg <= mem_wreg;
			wb_wdata <= mem_wdata;
		end    //if
	end      //always
			

endmodule