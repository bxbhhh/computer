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
	input wire                   flush,
	
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
    
	//��������CP0������ӿ�
    input wire                   ex_cp0_reg_we,
    input wire[4:0]              ex_cp0_reg_write_addr,
    input wire[`RegBus]          ex_cp0_reg_data,    
    
    //��������CP0������ӿ�
    output reg                   mem_cp0_reg_we,
    output reg[4:0]              mem_cp0_reg_write_addr,
    output reg[`RegBus]          mem_cp0_reg_data,
    
    //exception
    input wire[31:0]             ex_excepttype,
    input wire                   ex_is_in_delayslot,
    input wire[`RegBus]          ex_current_inst_address,
    
    output reg[31:0]            mem_excepttype,
    output reg                  mem_is_in_delayslot,
    output reg[`RegBus]         mem_current_inst_address,
      
	output wire[`DebugBus]        debugdata
);
    assign debugdata = {3'b0,ex_wd[4:0],ex_wdata[15:0]};


	   always @ (posedge clk) begin
            if(rst == `RstEnable) begin
                mem_wd <= `NOPRegAddr;
                mem_wreg <= `WriteDisable;
                mem_wdata <= `ZeroWord;    
                //����������ʵ��CP0��ʱ��ӵ�
                mem_cp0_reg_we <= `WriteDisable;
                mem_cp0_reg_write_addr <= 5'b00000;
                mem_cp0_reg_data <= `ZeroWord;    
                //exception
                mem_excepttype <= `ZeroWord;
                mem_is_in_delayslot <= `NotInDelaySlot;
                mem_current_inst_address <= `ZeroWord;
            end else if(flush == 1'b1 ) begin
                mem_wd <= `NOPRegAddr;
                mem_wreg <= `WriteDisable;
                mem_wdata <= `ZeroWord;
                mem_aluop <= `EXE_NOP_OP;
                mem_mem_addr <= `ZeroWord;
                mem_reg2 <= `ZeroWord;
                mem_cp0_reg_we <= `WriteDisable;
                mem_cp0_reg_write_addr <= 5'b00000;
                mem_cp0_reg_data <= `ZeroWord;
                mem_excepttype <= `ZeroWord;
                mem_is_in_delayslot <= `NotInDelaySlot;
                mem_current_inst_address <= `ZeroWord;
            end else if(stall[3] == `Stop && stall[4] == `NoStop) begin
                mem_wd <= `NOPRegAddr;
                mem_wreg <= `WriteDisable;
                mem_wdata <= `ZeroWord;      
                mem_aluop <= 8'b0;
                mem_mem_addr <= `ZeroWord;
                mem_reg2 <= `ZeroWord;   
                //����������ʵ��CP0��ʱ��ӵ�     
                mem_cp0_reg_we <= `WriteDisable;
                mem_cp0_reg_write_addr <= 5'b00000;
                mem_cp0_reg_data <= `ZeroWord;      
                //exception 
                mem_excepttype <= `ZeroWord;
                mem_is_in_delayslot <= `NotInDelaySlot;
                mem_current_inst_address <= `ZeroWord;                                          
            end else if (stall[3] == `NoStop) begin
                mem_wd <= ex_wd;
                mem_wreg <= ex_wreg;
                mem_wdata <= ex_wdata;
                
                mem_aluop <= ex_aluop;
                mem_mem_addr <= ex_mem_addr;
                mem_reg2 <= ex_reg2;  
                
                //����������ʵ��CP0��ʱ��ӵ�     
                mem_cp0_reg_we <= ex_cp0_reg_we;
                mem_cp0_reg_write_addr <= ex_cp0_reg_write_addr;
                mem_cp0_reg_data <= ex_cp0_reg_data;  
                //exception
                mem_excepttype <= ex_excepttype;
                mem_is_in_delayslot <= ex_is_in_delayslot;
                mem_current_inst_address <= ex_current_inst_address;                                                                       
              end    //if
          end      //always
			

endmodule