//////////////////////////////////////////////////////////////////////
// Module:  mem
// File:    mem.v
// Author:  BaiReny
// E-mail:  bry6789@163.com
// Description: 访存阶段
// Revision: 1.0
//////////////////////////////////////////////////////////////////////

`include "defines.vh"

module mem(

	input wire										rst,
	
	//来自执行阶段的信息	
	input wire[`RegAddrBus]       wd_i,
	input wire                    wreg_i,
	input wire[`RegBus]			  wdata_i,
	//来自执行阶段
	input wire[`AluOpBus]        aluop_i,
    input wire[`RegBus]          mem_addr_i,
    input wire[`RegBus]          reg2_i,	

	//来自memory的信息
	input wire[`RegBus]          mem_data_i,	
	
	//送到回写阶段的信息
	output reg[`RegAddrBus]      wd_o,
	output reg                   wreg_o,
	output reg[`RegBus]			 wdata_o,
	
	//送到数据存储器RAM中
	output reg[`RegBus]          mem_addr_o,
    output wire                  mem_we_o,
    output reg[3:0]              mem_sel_o,
    output reg[`RegBus]          mem_data_o,
    output reg                   mem_ce_o,
    
    //CP0相关
    input wire                   cp0_reg_we_i,
    input wire[4:0]              cp0_reg_write_addr_i,
    input wire[`RegBus]          cp0_reg_data_i,
        
    //CP0相关
    output reg                   cp0_reg_we_o,
    output reg[4:0]              cp0_reg_write_addr_o,
    output reg[`RegBus]          cp0_reg_data_o,
    
    //exception
    input wire[31:0]             excepttype_i,
    input wire                   is_in_delayslot_i,
    input wire[`RegBus]          current_inst_address_i,    
        
    //CP0的各个寄存器的值，但不一定是最新的值，要防止回写阶段指令写CP0
    input wire[`RegBus]          cp0_status_i,
    input wire[`RegBus]          cp0_cause_i,
    input wire[`RegBus]          cp0_epc_i,
    
    //回写阶段的指令是否要写CP0，用来检测数据相关
    input wire                    wb_cp0_reg_we,
    input wire[4:0]               wb_cp0_reg_write_addr,
    input wire[`RegBus]           wb_cp0_reg_data,
    
    output reg[31:0]             excepttype_o,
    output wire[`RegBus]          cp0_epc_o,
    output wire                  is_in_delayslot_o,
    output wire[`RegBus]         current_inst_address_o,
    
	output wire[`DebugBus]      debugdata,
	output wire[`DebugBus]      debugdatanew
);
    assign debugdata = {mem_data_i[7:0], mem_addr_i[15:0]} ;
    assign debugdatanew = {mem_data_i[15:8], mem_addr_i[31:16]};
    
	wire[`RegBus] zero32;
	//exception
	reg[`RegBus]          cp0_status;
    reg[`RegBus]          cp0_cause;
    reg[`RegBus]          cp0_epc;    
    
	reg                   mem_we;

	assign mem_we_o = mem_we & (~(|excepttype_o)); //外部数据存储RAM读写信号,最终给出
	assign zero32 = `ZeroWord;
    
    assign is_in_delayslot_o = is_in_delayslot_i;
    assign current_inst_address_o = current_inst_address_i;
    assign cp0_epc_o = cp0_epc;
    
    //exception cp0 status
    always @ (*) begin
        if(rst == `RstEnable) begin
            cp0_status <= `ZeroWord;
        end else if((wb_cp0_reg_we == `WriteEnable) && 
                                (wb_cp0_reg_write_addr == `CP0_REG_STATUS ))begin
            cp0_status <= wb_cp0_reg_data;
        end else begin
            cp0_status <= cp0_status_i;
        end
    end
    //exception cp0 epc
    always @ (*) begin
        if(rst == `RstEnable) begin
            cp0_epc <= `ZeroWord;
        end else if((wb_cp0_reg_we == `WriteEnable) && 
                               (wb_cp0_reg_write_addr == `CP0_REG_EPC ))begin
            cp0_epc <= wb_cp0_reg_data;
        end else begin
          cp0_epc <= cp0_epc_i;
        end
    end
    //exception cp0 cause
    always @ (*) begin
        if(rst == `RstEnable) begin
            cp0_cause <= `ZeroWord;
        end else if((wb_cp0_reg_we == `WriteEnable) && 
                                (wb_cp0_reg_write_addr == `CP0_REG_CAUSE ))begin
            cp0_cause[9:8] <= wb_cp0_reg_data[9:8];
            cp0_cause[22] <= wb_cp0_reg_data[22];
            cp0_cause[23] <= wb_cp0_reg_data[23];
        end else begin
          cp0_cause <= cp0_cause_i;
        end
    end
    
    //exception 类型
    always @ (*) begin
        if(rst == `RstEnable) begin
            excepttype_o <= `ZeroWord;
        end else begin
            excepttype_o <= `ZeroWord;
            
            if(current_inst_address_i != `ZeroWord) begin
                if(((cp0_cause[15:8] & (cp0_status[15:8])) != 8'h00) && (cp0_status[1] == 1'b0) && 
                            (cp0_status[0] == 1'b1)) begin
                    excepttype_o <= 32'h00000001;        //interrupt
                end else if(excepttype_i[8] == 1'b1) begin
                  excepttype_o <= 32'h00000008;        //syscall
                end else if(excepttype_i[9] == 1'b1) begin
                    excepttype_o <= 32'h0000000a;        //inst_invalid
                end else if(excepttype_i[10] ==1'b1) begin
                    excepttype_o <= 32'h0000000d;        //trap
                end else if(excepttype_i[11] == 1'b1) begin  //ov
                    excepttype_o <= 32'h0000000c;
                end else if(excepttype_i[12] == 1'b1) begin  //返回指令
                    excepttype_o <= 32'h0000000e;
                end
            end
                
        end
    end    
	
	always @ (*) begin
		if(rst == `RstEnable) begin
		    wd_o <= `NOPRegAddr;
		    wreg_o <= `WriteDisable;
            wdata_o <= `ZeroWord;
            mem_addr_o <= `ZeroWord;
            mem_we <= `WriteDisable;
            mem_sel_o <= 4'b0000;
            mem_data_o <= `ZeroWord;
            mem_ce_o <= `ChipDisable;    
            //CP0    
            cp0_reg_we_o <= `WriteDisable;
            cp0_reg_write_addr_o <= 5'b00000;
            cp0_reg_data_o <= `ZeroWord;               
		end else begin
		    wd_o <= wd_i;
			wreg_o <= wreg_i;
			wdata_o <= wdata_i;
			mem_we <= `WriteDisable;
            mem_addr_o <= `ZeroWord;
            mem_sel_o <= 4'b1111;
            mem_ce_o <= `ChipDisable;
            //CP0
            cp0_reg_we_o <= cp0_reg_we_i;
            cp0_reg_write_addr_o <= cp0_reg_write_addr_i;
            cp0_reg_data_o <= cp0_reg_data_i; 
			case (aluop_i)
                `EXE_LB_OP:        begin
                    mem_addr_o <= mem_addr_i;
                    mem_we <= `WriteDisable;
                    mem_ce_o <= `ChipEnable;
                    case (mem_addr_i[1:0])
                        2'b11:    begin
                            wdata_o <= {{24{mem_data_i[31]}},mem_data_i[31:24]};
                            mem_sel_o <= 4'b1000;
                        end
                        2'b10:    begin
                            wdata_o <= {{24{mem_data_i[23]}},mem_data_i[23:16]};
                            mem_sel_o <= 4'b0100;
                        end
                        2'b01:    begin
                            wdata_o <= {{24{mem_data_i[15]}},mem_data_i[15:8]};
                            mem_sel_o <= 4'b0010;
                        end
                        2'b00:    begin
                            wdata_o <= {{24{mem_data_i[7]}},mem_data_i[7:0]};
                            mem_sel_o <= 4'b0001;
                        end
                        default:    begin
                            wdata_o <= `ZeroWord;
                        end
                    endcase
                end 
				`EXE_LBU_OP:		begin
                    mem_addr_o <= mem_addr_i;
                    mem_we <= `WriteDisable;
                    mem_ce_o <= `ChipEnable;
                    case (mem_addr_i[1:0])
                        2'b11:    begin
                            wdata_o <= {{24{1'b0}},mem_data_i[31:24]};
                            mem_sel_o <= 4'b1000;
                        end
                        2'b10:    begin
                            wdata_o <= {{24{1'b0}},mem_data_i[23:16]};
                            mem_sel_o <= 4'b0100;
                        end
                        2'b01:    begin
                            wdata_o <= {{24{1'b0}},mem_data_i[15:8]};
                            mem_sel_o <= 4'b0010;
                        end
                        2'b00:    begin
                            wdata_o <= {{24{1'b0}},mem_data_i[7:0]};
                            mem_sel_o <= 4'b0001;
                        end
                        default:    begin
                            wdata_o <= `ZeroWord;
                        end
                    endcase                
                end
				`EXE_LW_OP:		begin
                    mem_addr_o <= mem_addr_i;
                    mem_we <= `WriteDisable;
                    wdata_o <= mem_data_i;
                    mem_sel_o <= 4'b1111;
                    mem_ce_o <= `ChipEnable;        
                end
				`EXE_SB_OP:		begin
                    mem_addr_o <= mem_addr_i;
                    mem_we <= `WriteEnable;
                    mem_data_o <= {reg2_i[7:0],reg2_i[7:0],reg2_i[7:0],reg2_i[7:0]};
                    mem_ce_o <= `ChipEnable;
                    case (mem_addr_i[1:0])
                        2'b11:    begin
                            mem_sel_o <= 4'b1000;
                        end
                        2'b10:    begin
                            mem_sel_o <= 4'b0100;
                        end
                        2'b01:    begin
                            mem_sel_o <= 4'b0010;
                        end
                        2'b00:    begin
                            mem_sel_o <= 4'b0001;    
                        end
                        default:    begin
                            mem_sel_o <= 4'b0000;
                        end
                    endcase                
                end
				`EXE_SW_OP:		begin
                    mem_addr_o <= mem_addr_i;
                    mem_we <= `WriteEnable;
                    mem_data_o <= reg2_i;
                    mem_sel_o <= 4'b1111;    
                    mem_ce_o <= `ChipEnable;        
                end
                default:		begin
                end
            endcase                                                                           			
		end    //if
	end      //always
			

endmodule