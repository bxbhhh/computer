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
        * ��CP0�Ĵ�����д����
        */
    	always @ (posedge clk) begin
        if(rst == `RstEnable) begin
        
            //Count�Ĵ����ĳ�ʼֵ������Ϊ0
            count_o <= `ZeroWord;
            
            //Compare�Ĵ����ĳ�ʼֵ������Ϊ0
            compare_o <= `ZeroWord;
            
            //Status�Ĵ����ĳ�ʼֵ������CU�ֶ�Ϊ4'b0001����ʾЭ������CP0����
            status_o <= 32'b00010000000000000000000000000000;
            
            //Cause�Ĵ����ĳ�ʼֵ������Ϊ0
            cause_o <= `ZeroWord;
            
            //EPC�Ĵ����ĳ�ʼֵ������Ϊ0
            epc_o <= `ZeroWord;
            
            
            //Config�Ĵ����ĳ�ʼֵ������BE�ֶ�Ϊ1����ʾ�����ڴ��ģʽ(MSB)
            config_o <= 32'b00000000000000001000000000000000;
            //PRId�Ĵ����ĳ�ʼֵ��������������L����Ӧ����0x48
            //������0x1����ʾ�ǻ������ͣ��汾����1.0
            prid_o <= 32'b00000000010011000000000100000010;
            timer_int_o <= `InterruptNotAssert;
        end else begin
        
          count_o <= count_o + 1 ;  //Count�Ĵ�����ÿ��ʱ�����ڼ�1
          cause_o[15:10] <= int_i;  //Cause�Ĵ����ĵ�10~15bit�����ⲿ�ж�����
        
            //��Compare�Ĵ�����Ϊ0����Count�Ĵ�����ֵ����Compare�Ĵ�����ֵʱ��
            //������ź�timer_int_o��Ϊ1����ʾʱ���жϷ���
            if(compare_o != `ZeroWord && count_o == compare_o) begin
                timer_int_o <= `InterruptAssert;
            end
                    
            if(we_i == `WriteEnable) begin
                case (waddr_i) 
                    `CP0_REG_COUNT:        begin    //дCount�Ĵ���
                        count_o <= data_i;
                    end
                    `CP0_REG_COMPARE:    begin      //дCompare�Ĵ���
                        compare_o <= data_i;
                        timer_int_o <= `InterruptNotAssert;
                    end
                    `CP0_REG_STATUS:    begin       //дStatus�Ĵ���
                        status_o <= data_i;
                    end
                    `CP0_REG_EPC:    begin          //дEPC�Ĵ���
                        epc_o <= data_i;
                    end
                    `CP0_REG_CAUSE:    begin        //дCause�Ĵ���
                        //ֻ��IP[1:0],IV,WP�ֶ��ǿ�д��
                        cause_o[9:8] <= data_i[9:8];
                        cause_o[23] <= data_i[23];
                        cause_o[22] <= data_i[22];
                    end                    
                endcase  //case addr_i
            end
            
            case (excepttype_i)
                32'h00000001:        begin  //�ⲿ�ж�
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
                32'h00000008:        begin  //ϵͳ����
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
                32'h0000000a:        begin  //��Чָ���쳣
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
                32'h0000000d:        begin  //�����쳣
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
//                     32'h0000000c:        begin   //���
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
                  32'h0000000e:   begin //�쳣����
                    status_o[1] <= 1'b0;
                   end
                   default:                begin
                   end
              endcase
            
            
        end    //if
    end      //always
            
            
    /*
    * ��CP0�Ĵ����Ķ�����
    */
    always @ (*) begin
        if(rst == `RstEnable) begin
            data_o <= `ZeroWord;
        end else begin
                case (raddr_i) 
                    `CP0_REG_COUNT:    begin    //��Count�Ĵ���
                        data_o <= count_o ;
                    end
                    `CP0_REG_COMPARE:    begin  //��Compare�Ĵ���
                        data_o <= compare_o ;
                    end
                    `CP0_REG_STATUS:    begin   //��Status�Ĵ���
                        data_o <= status_o ;
                    end
                    `CP0_REG_CAUSE:    begin    //��Cause�Ĵ���
                        data_o <= cause_o ;
                    end
                    `CP0_REG_EPC:    begin      //��EPC�Ĵ���
                        data_o <= epc_o ;
                    end
                    `CP0_REG_PrId:    begin     //��PRId�Ĵ���
                        data_o <= prid_o ;
                    end
                    `CP0_REG_CONFIG:    begin   //��Config�Ĵ���
                        data_o <= config_o ;
                    end    
                    default:  begin
                    end            
                endcase  //case addr_i            
        end    //if
    end      //always
endmodule
