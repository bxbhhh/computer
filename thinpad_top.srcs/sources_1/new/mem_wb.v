//////////////////////////////////////////////////////////////////////
// Module:  mem_wb
// File:    mem_wb.v
// Author:  BaiReny
// E-mail:  bry6789@163.com
// Description: MEM/WB阶段的寄存器
// Revision: 1.0
//////////////////////////////////////////////////////////////////////

`include "defines.vh"

module mem_wb(

	input	wire		clk,
	input wire			rst,
	input wire[5:0]    stall,
	input wire flush,
	

	//来自访存阶段的信息	
	input wire[`RegAddrBus]       mem_wd,
	input wire                    mem_wreg,
	input wire[`RegBus]					 mem_wdata,

	//送到回写阶段的信息
	output reg[`RegAddrBus]      wb_wd,
	output reg                   wb_wreg,
	output reg[`RegBus]					 wb_wdata,	  
	
	//CP0
    input wire                   mem_cp0_reg_we,
    input wire[4:0]              mem_cp0_reg_write_addr,
    input wire[`RegBus]          mem_cp0_reg_data,      
        
    //CP0
    output reg                   wb_cp0_reg_we,
    output reg[4:0]              wb_cp0_reg_write_addr,
    output reg[`RegBus]          wb_cp0_reg_data,  
	     
	output wire[`DebugBus]        debugdata       
);
    assign debugdata = {3'b0,wb_wd[4:0],wb_wdata[15:0]};


	   always @ (posedge clk) begin
            if(rst == `RstEnable) begin
                  wb_wd <= `NOPRegAddr;
                  wb_wreg <= `WriteDisable;
                  wb_wdata <= `ZeroWord;
                  //CP0
                  wb_cp0_reg_we <= `WriteDisable;
                  wb_cp0_reg_write_addr <= 5'b00000;
                  wb_cp0_reg_data <= `ZeroWord;    
              end else if(flush == 1'b1 ) begin
                  wb_wd <= `NOPRegAddr;
                  wb_wreg <= `WriteDisable;
                  wb_wdata <= `ZeroWord;
                  wb_cp0_reg_we <= `WriteDisable;
                  wb_cp0_reg_write_addr <= 5'b00000;
                  wb_cp0_reg_data <= `ZeroWord;                        
            end else if(stall[4] == `Stop && stall[5] == `NoStop) begin
                  wb_wd <= `NOPRegAddr;
                  wb_wreg <= `WriteDisable;
                  wb_wdata <= `ZeroWord;    
                  //CP0
                  wb_cp0_reg_we <= `WriteDisable;
                  wb_cp0_reg_write_addr <= 5'b00000;
                  wb_cp0_reg_data <= `ZeroWord;                                                      
            end else if (stall[4] == `NoStop) begin  
                wb_wd <= mem_wd;
                wb_wreg <= mem_wreg;
                wb_wdata <= mem_wdata;
                //CP0
                wb_cp0_reg_we <= mem_cp0_reg_we;
                wb_cp0_reg_write_addr <= mem_cp0_reg_write_addr;
                wb_cp0_reg_data <= mem_cp0_reg_data;                      
            end    //if
        end      //always
			

endmodule