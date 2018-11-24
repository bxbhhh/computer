//////////////////////////////////////////////////////////////////////
// Module:  ex
// File:    ex.v
// Author:  BaiReny
// E-mail:  bry6789@163.com
// Description: 执行阶段
// Revision: 1.0
//////////////////////////////////////////////////////////////////////

`include "defines.vh"

module ex(

	input wire	rst,
	
	//送到执行阶段的信息
	input wire[`AluOpBus]         aluop_i,
	input wire[`AluSelBus]        alusel_i,
	input wire[`RegBus]           reg1_i,
	input wire[`RegBus]           reg2_i,
	input wire[`RegAddrBus]       wd_i,
	input wire                    wreg_i,
	
    //处于执行阶段的转移指令要保存的返回地址
    input wire[`RegBus]           link_address_i,
    //当前执行阶段的指令是否处于延迟槽
    input wire                    is_in_delayslot_i,    

	
	output reg[`RegAddrBus]       wd_o,
	output reg                    wreg_o,
	output reg[`RegBus]			  wdata_o,
	output reg					  stallreq       
	
);
	reg[`RegBus] logicout;//保存逻辑运算结果
    reg[`RegBus] shiftres;//保存移位运算结果
 	reg[`RegBus] moveres; //保存移动操作的结果
 	reg[`RegBus] arithmeticres; //保存算数运算的结果
    
    wire[`RegBus] reg1_i_not; //保存输入的第一个操作数reg1_i取反后的值    
    wire[`RegBus] result_sum; //保存加法的结果
    
    assign result_num = reg1_i + reg2_i;
    assign reg1_i_not = ~reg1_i;
    
 	
 //进行逻辑运算   
	always @ (*) begin
		if(rst == `RstEnable) begin
			logicout <= `ZeroWord;
		end else begin
			case (aluop_i)
				`EXE_OR_OP:			begin     //逻辑或运算
					logicout <= reg1_i | reg2_i;
				end
				`EXE_AND_OP:		begin     //逻辑与运算
                    logicout <= reg1_i & reg2_i;
                end
                `EXE_NOR_OP:        begin     //逻辑或非运算
                    logicout <= ~(reg1_i |reg2_i);
                end
                `EXE_XOR_OP:        begin    //逻辑异或运算
                    logicout <= reg1_i ^ reg2_i;
                end				
				
				default:				begin
					logicout <= `ZeroWord;
				end
			endcase
		end    //if
	end      //always

//进行逻辑移位运算
    always @ (*) begin
		if(rst == `RstEnable) begin
			shiftres <= `ZeroWord;
		end else begin
			case (aluop_i)
				`EXE_SLL_OP:			begin            //逻辑左移
					shiftres <= reg2_i << reg1_i[4:0] ;
				end
				`EXE_SRL_OP:		begin               //逻辑右移
					shiftres <= reg2_i >> reg1_i[4:0];
				end
				default:				begin
					shiftres <= `ZeroWord;
				end
			endcase
		end    //if
	end      //always

//进行移动操作 movn	
    always @ (*) begin
        if(rst == `RstEnable) begin
            moveres <= `ZeroWord;
        end else begin
            moveres <= `ZeroWord;
            case (aluop_i)
                `EXE_MOVN_OP:        begin
                 moveres <= reg1_i;
                end
                default : begin
                end
            endcase
        end
    end    
    
    always @ (*) begin
            if(rst == `RstEnable) begin
                arithmeticres <= `ZeroWord;
            end else begin
                case (aluop_i)
                    `EXE_ADDU_OP, `EXE_ADDIU_OP:        begin
                        arithmeticres <= result_sum; 
                     end      
                    `EXE_CLO_OP:        begin
                        arithmeticres <= (reg1_i_not[31] ? 0 : reg1_i_not[30] ? 1 : reg1_i_not[29] ? 2 :
                                                         reg1_i_not[28] ? 3 : reg1_i_not[27] ? 4 : reg1_i_not[26] ? 5 :
                                                         reg1_i_not[25] ? 6 : reg1_i_not[24] ? 7 : reg1_i_not[23] ? 8 : 
                                                         reg1_i_not[22] ? 9 : reg1_i_not[21] ? 10 : reg1_i_not[20] ? 11 :
                                                         reg1_i_not[19] ? 12 : reg1_i_not[18] ? 13 : reg1_i_not[17] ? 14 : 
                                                         reg1_i_not[16] ? 15 : reg1_i_not[15] ? 16 : reg1_i_not[14] ? 17 : 
                                                         reg1_i_not[13] ? 18 : reg1_i_not[12] ? 19 : reg1_i_not[11] ? 20 :
                                                         reg1_i_not[10] ? 21 : reg1_i_not[9] ? 22 : reg1_i_not[8] ? 23 : 
                                                         reg1_i_not[7] ? 24 : reg1_i_not[6] ? 25 : reg1_i_not[5] ? 26 : 
                                                         reg1_i_not[4] ? 27 : reg1_i_not[3] ? 28 : reg1_i_not[2] ? 29 : 
                                                         reg1_i_not[1] ? 30 : reg1_i_not[0] ? 31 : 32) ;
                    end
                    default:                begin
                        arithmeticres <= `ZeroWord;
                    end
                endcase
            end
        end 

//根据alusel_i选择最终的运算结果
    always @ (*) begin
	   wd_o <= wd_i;	 	 	
	   wreg_o <= wreg_i;
	   case ( alusel_i ) 
            `EXE_RES_LOGIC:		begin
                wdata_o <= logicout;    //选择逻辑运算为最终运算结果
            end
            `EXE_RES_SHIFT:		begin
                 wdata_o <= shiftres;   //选择移位运算作为最终结果
            end
            `EXE_RES_MOVE:		begin
                wdata_o <= moveres;
            end 
            `EXE_RES_ARITHMETIC:	begin
                wdata_o <= arithmeticres;  
             end
             `EXE_RES_JUMP_BRANCH:	begin
                 wdata_o <= link_address_i;
             end                   	 		 	
             default:					begin
                wdata_o <= `ZeroWord;
            end
         endcase
    end	

endmodule