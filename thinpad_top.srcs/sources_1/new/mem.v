//////////////////////////////////////////////////////////////////////
// Module:  mem
// File:    mem.v
// Author:  BaiReny
// E-mail:  bry6789@163.com
// Description: �ô�׶�
// Revision: 1.0
//////////////////////////////////////////////////////////////////////

`include "defines.vh"

module mem(

	input wire										rst,
	
	//����ִ�н׶ε���Ϣ	
	input wire[`RegAddrBus]       wd_i,
	input wire                    wreg_i,
	input wire[`RegBus]			  wdata_i,
	//����ִ�н׶�
	input wire[`AluOpBus]        aluop_i,
    input wire[`RegBus]          mem_addr_i,
    input wire[`RegBus]          reg2_i,	

	//����memory����Ϣ
	input wire[`RegBus]          mem_data_i,	
	
	//�͵���д�׶ε���Ϣ
	output reg[`RegAddrBus]      wd_o,
	output reg                   wreg_o,
	output reg[`RegBus]			 wdata_o,
	
	//�͵����ݴ洢��RAM��
	output reg[`RegBus]          mem_addr_o,
    output wire                  mem_we_o,
    output reg[3:0]              mem_sel_o,
    output reg[`RegBus]          mem_data_o,
    output reg                   mem_ce_o,    
	output wire[`DebugBus]      debugdata,
	output wire[`DebugBus]      debugdatanew
);
    assign debugdata = {mem_data_i[7:0], mem_addr_i[15:0]} ;
    assign debugdatanew = {mem_data_i[15:8], mem_addr_i[31:16]};
    
	wire[`RegBus] zero32;
	reg                   mem_we;

	assign mem_we_o = mem_we ; //�ⲿ���ݴ洢RAM��д�ź�
	assign zero32 = `ZeroWord;

	
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
		end else begin
		    wd_o <= wd_i;
			wreg_o <= wreg_i;
			wdata_o <= wdata_i;
			mem_we <= `WriteDisable;
            mem_addr_o <= `ZeroWord;
            mem_sel_o <= 4'b1111;
            mem_ce_o <= `ChipDisable;
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