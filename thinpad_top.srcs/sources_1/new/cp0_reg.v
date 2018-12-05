`timescale 1ns / 1ps
`include "defines.vh"

module cp0_reg(
    
    input wire clk,
    input wire rst,
    
    input wire we_i,
    input wire[4:0]    waddr_i,
    input wire[4:0]    raddr_i,
    input wire[`RegBus]    data_i,
    
    input wire[5:0]               int_i,
   
    
    output reg[`RegBus]           data_o,
    output reg[`RegBus]           count_o,
    output reg[`RegBus]           compare_o,
    output reg[`RegBus]           status_o,
    output reg[`RegBus]           cause_o,
    output reg[`RegBus]           epc_o,
    output reg[`RegBus]           config_o,
    output reg[`RegBus]           prid_o,
    //exception
    input wire[31:0]              excepttype_i,
    input wire[`RegBus]           current_inst_addr_i,
    input wire                    is_in_delayslot_i,
    
    output reg                   timer_int_o,
    output wire[`DebugBus] debugdata_w,
    output wire[`DebugBus] debugdata_r
    );
    assign debugdata_w = {3'b0,waddr_i[4:0],data_i[15:0]};
     assign debugdata_r = {3'b0,raddr_i[4:0],data_o[15:0]};
    
        /*
        * 对CP0寄存器的写操作
        */
    	always @ (posedge clk) begin
        if(rst == `RstEnable) begin
        
            //Count寄存器的初始值，设置为0
            count_o <= `ZeroWord;
            
            //Compare寄存器的初始值，设置为0
            compare_o <= `ZeroWord;
            
            //Status寄存器的初始值，其中CU字段为4'b0001，表示协处理器CP0存在
            status_o <= 32'b00010000000000000000000000000000;
            
            //Cause寄存器的初始值，设置为0
            cause_o <= `ZeroWord;
            
            //EPC寄存器的初始值，设置为0
            epc_o <= `ZeroWord;
            
            
            //Config寄存器的初始值，其中BE字段为1，表示工作在大端模式(MSB)
            config_o <= 32'b00000000000000001000000000000000;
            //PRId寄存器的初始值，其中制作者是L，对应的是0x48
            //类型是0x1，表示是基本类型，版本号是1.0
            prid_o <= 32'b00000000010011000000000100000010;
            timer_int_o <= `InterruptNotAssert;
        end else begin
        
          count_o <= count_o + 1 ;  //Count寄存器在每个时钟周期加1
          cause_o[15:10] <= int_i;  //Cause寄存器的第10~15bit保存外部中断声明
        
            //当Compare寄存器不为0，且Count寄存器的值等于Compare寄存器的值时，
            //将输出信号timer_int_o置为1，表示时钟中断发生
            if(compare_o != `ZeroWord && count_o == compare_o) begin
                timer_int_o <= `InterruptAssert;
            end
                    
            if(we_i == `WriteEnable) begin
                case (waddr_i) 
                    `CP0_REG_COUNT:        begin    //写Count寄存器
                        count_o <= data_i;
                    end
                    `CP0_REG_COMPARE:    begin      //写Compare寄存器
                        compare_o <= data_i;
                        timer_int_o <= `InterruptNotAssert;
                    end
                    `CP0_REG_STATUS:    begin       //写Status寄存器
                        status_o <= data_i;
                    end
                    `CP0_REG_EPC:    begin          //写EPC寄存器
                        epc_o <= data_i;
                    end
                    `CP0_REG_CAUSE:    begin        //写Cause寄存器
                        //只有IP[1:0],IV,WP字段是可写的
                        cause_o[9:8] <= data_i[9:8];
                        cause_o[23] <= data_i[23];
                        cause_o[22] <= data_i[22];
                    end                    
                endcase  //case addr_i
            end
            
            case (excepttype_i)
                32'h00000001:        begin  //外部中断
                    if(is_in_delayslot_i == `InDelaySlot ) begin
                        epc_o <= current_inst_addr_i - 4 ;
                        cause_o[31] <= 1'b1;
                    end else begin
                        epc_o <= current_inst_addr_i;
                        cause_o[31] <= 1'b0;
                    end
                        status_o[1] <= 1'b1;
                        cause_o[6:2] <= 5'b00000;
                    end
                32'h00000008:        begin  //系统调用
                    if(status_o[1] == 1'b0) begin
                        if(is_in_delayslot_i == `InDelaySlot ) begin
                            epc_o <= current_inst_addr_i - 4 ;
                            cause_o[31] <= 1'b1;
                        end else begin
                            epc_o <= current_inst_addr_i;
                            cause_o[31] <= 1'b0;
                        end
                    end
                    status_o[1] <= 1'b1;
                    cause_o[6:2] <= 5'b01000;     
                end
                32'h0000000a:        begin  //无效指令异常
                    if(status_o[1] == 1'b0) begin
                        if(is_in_delayslot_i == `InDelaySlot ) begin
                            epc_o <= current_inst_addr_i - 4 ;
                            cause_o[31] <= 1'b1;
                        end else begin
                            epc_o <= current_inst_addr_i;
                            cause_o[31] <= 1'b0;
                        end
                    end
                    status_o[1] <= 1'b1;
                    cause_o[6:2] <= 5'b01010;
                end
                32'h0000000d:        begin  //自陷异常
                                if(status_o[1] == 1'b0) begin
                                    if(is_in_delayslot_i == `InDelaySlot ) begin
                                        epc_o <= current_inst_addr_i - 4 ;
                                        cause_o[31] <= 1'b1;
                                    end else begin
                                      epc_o <= current_inst_addr_i;
                                      cause_o[31] <= 1'b0;
                                    end
                                end
                                status_o[1] <= 1'b1;
                                cause_o[6:2] <= 5'b01101;                    
                 end
//                     32'h0000000c:        begin   //溢出
//                                if(status_o[1] == 1'b0) begin
//                                    if(is_in_delayslot_i == `InDelaySlot ) begin
//                                        epc_o <= current_inst_addr_i - 4 ;
//                                        cause_o[31] <= 1'b1;
//                                    end else begin
//                                      epc_o <= current_inst_addr_i;
//                                      cause_o[31] <= 1'b0;
//                                    end
//                                end
//                                status_o[1] <= 1'b1;
//                                cause_o[6:2] <= 5'b01100;                    
//                      end
                  32'h0000000e:   begin //异常返回
                    status_o[1] <= 1'b0;
                   end
                   default:                begin
                   end
              endcase
            
            
        end    //if
    end      //always
            
            
    /*
    * 对CP0寄存器的读操作
    */
    always @ (*) begin
        if(rst == `RstEnable) begin
            data_o <= `ZeroWord;
        end else begin
                case (raddr_i) 
                    `CP0_REG_COUNT:    begin    //读Count寄存器
                        data_o <= count_o ;
                    end
                    `CP0_REG_COMPARE:    begin  //读Compare寄存器
                        data_o <= compare_o ;
                    end
                    `CP0_REG_STATUS:    begin   //读Status寄存器
                        data_o <= status_o ;
                    end
                    `CP0_REG_CAUSE:    begin    //读Cause寄存器
                        data_o <= cause_o ;
                    end
                    `CP0_REG_EPC:    begin      //读EPC寄存器
                        data_o <= epc_o ;
                    end
                    `CP0_REG_PrId:    begin     //读PRId寄存器
                        data_o <= prid_o ;
                    end
                    `CP0_REG_CONFIG:    begin   //读Config寄存器
                        data_o <= config_o ;
                    end    
                    default:  begin
                    end            
                endcase  //case addr_i            
        end    //if
    end      //always
endmodule
