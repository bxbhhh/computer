//////////////////////////////////////////////////////////////////////
// Module:  ex_mem
// File:    ex_mem.v
// Author:  BaiReny
// E-mail:  bry6789@163.com
// Description: EX/MEM�׶εļĴ���
// Revision: 1.0
//////////////////////////////////////////////////////////////////////

`include "defines.vh"

module ex_mem(

	input	wire				  clk,
	input wire					  rst,
	input wire[5:0]              stall,
	
	//����ִ�н׶ε���Ϣ	
	input wire[`RegAddrBus]       ex_wd,
	input wire                    ex_wreg,
	input wire[`RegBus]			   ex_wdata, 
     //Ϊʵ�ּ��ء��ô�ָ����������ӿ�
    input wire[`AluOpBus]        ex_aluop,
    input wire[`RegBus]          ex_mem_addr,
    input wire[`RegBus]          ex_reg2,	
	
	//�͵��ô�׶ε���Ϣ
	output reg[`RegAddrBus]      mem_wd,
	output reg                   mem_wreg,
	output reg[`RegBus]			  mem_wdata,
	
	//Ϊʵ�ּ��ء��ô�ָ����������ӿ�
    output reg[`AluOpBus]        mem_aluop,
    output reg[`RegBus]          mem_mem_addr,
    output reg[`RegBus]          mem_reg2,
	
	output wire[`DebugBus]        debugdata
);
    assign debugdata = {3'b0,ex_wd[4:0],ex_wdata[15:0]};


	always @ (posedge clk) begin
		if(rst == `RstEnable) begin
			mem_wd <= `NOPRegAddr;
			mem_wreg <= `WriteDisable;
		    mem_wdata <= `ZeroWord;	
		end else if(stall[3] == `Stop && stall[4] == `NoStop) begin
            mem_wd <= `NOPRegAddr;
            mem_wreg <= `WriteDisable;
            mem_wdata <= `ZeroWord;      
            mem_aluop <= 8'b0;
            mem_mem_addr <= `ZeroWord;
            mem_reg2 <= `ZeroWord;                         
//        end else  begin
        end else if (stall[3] == `NoStop) begin
            mem_wd <= ex_wd;
            mem_wreg <= ex_wreg;
            mem_wdata <= ex_wdata;
			
			mem_aluop <= ex_aluop;
            mem_mem_addr <= ex_mem_addr;
            mem_reg2 <= ex_reg2;                                                   
          end    //if
      end      //always
			

endmodule