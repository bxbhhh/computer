//////////////////////////////////////////////////////////////////////
// Module:  id
// File:    id.v
// Author:  BaiReny
// E-mail:  bry6789@163.com
// Description: 译码阶段
// Revision: 1.0
//////////////////////////////////////////////////////////////////////

`include "defines.vh"

module id(

	input wire							rst,
	input wire[`InstAddrBus]			pc_i,
	input wire[`InstBus]               inst_i,

	//处于执行阶段的指令要写入的目的寄存器信息
	input wire								ex_wreg_i,
	input wire[`RegBus]						ex_wdata_i,
	input wire[`RegAddrBus]                ex_wd_i,
	
	//处于执行阶段的指令的一些信息，用于解决load相关
    input wire[`AluOpBus]                    ex_aluop_i,
    
	//处于访存阶段的指令要写入的目的寄存器信息
	input wire					   mem_wreg_i,
	input wire[`RegBus]			   mem_wdata_i,
	input wire[`RegAddrBus]       mem_wd_i,
	
	input wire[`RegBus]           reg1_data_i,
	input wire[`RegBus]           reg2_data_i,

	//如果上一条指令是转移指令，那么下一条指令在译码的时候is_in_delayslot为true
	input wire                    is_in_delayslot_i,	

	//送到regfile的信息
	output reg                    reg1_read_o,
	output reg                    reg2_read_o,     
	output reg[`RegAddrBus]       reg1_addr_o,
	output reg[`RegAddrBus]       reg2_addr_o, 	      
	
	//送到执行阶段的信息
	output reg[`AluOpBus]         aluop_o,
	output reg[`AluSelBus]        alusel_o,
	output reg[`RegBus]           reg1_o,
	output reg[`RegBus]           reg2_o,
	output reg[`RegAddrBus]       wd_o,
	output reg                    wreg_o,
	output wire[`RegBus]          inst_o, //新增加输出接口	
	
	output reg                    next_inst_in_delayslot_o,
    
    output reg                    branch_flag_o,
    output reg[`RegBus]           branch_target_address_o,       
    output reg[`RegBus]           link_addr_o,
    output reg                    is_in_delayslot_o,	
    
    //异常处理 
    output wire[31:0]             excepttype_o,
    output wire[`RegBus]          current_inst_address_o,
	
	output wire                   stallreq	//加载存储指令时信号赋值
);

  wire[5:0] op = inst_i[31:26];
  wire[4:0] op2 = inst_i[10:6];
  wire[5:0] op3 = inst_i[5:0];
  wire[4:0] op4 = inst_i[20:16];
  reg[`RegBus]	imm;
  reg instvalid;
  wire[`RegBus] pc_plus_8;
  wire[`RegBus] pc_plus_4;
  wire[`RegBus] imm_sll2_signedext;  
  
  reg stallreq_for_reg1_loadrelate;
  reg stallreq_for_reg2_loadrelate;
  wire pre_inst_is_load;
  
  reg excepttype_is_syscall;// 是否是系统调用syscall
  reg excepttype_is_eret; // 是否是异常返回eret
  
  assign pc_plus_8 = pc_i + 8;//保存当前后面第二条指令地址
  assign pc_plus_4 = pc_i +4;//保存当前后面第一条指令地址
  //分支指令中的offset左移两位，然后扩展32位
  assign imm_sll2_signedext = {{14{inst_i[15]}}, inst_i[15:0], 2'b00 };  
  assign stallreq = stallreq_for_reg1_loadrelate | stallreq_for_reg2_loadrelate;
  assign pre_inst_is_load = ((ex_aluop_i == `EXE_LB_OP) || 
                                                      (ex_aluop_i == `EXE_LBU_OP)||
                                                      (ex_aluop_i == `EXE_LW_OP)) ? 1'b1 : 1'b0;
  //低八位给外部中断，[8]是系统调用，[12]是eret                                             
  assign excepttype_o = {19'b0, excepttype_is_eret,2'b0,1'b0, excepttype_is_syscall,8'b0};
  assign current_inst_address_o = pc_i;
    
  assign inst_o = inst_i;
  
	always @ (*) begin	
		if (rst == `RstEnable) begin
			aluop_o <= `EXE_NOP_OP;
			alusel_o <= `EXE_RES_NOP;
			wd_o <= `NOPRegAddr;
			wreg_o <= `WriteDisable;
			instvalid <= `InstValid;
			reg1_read_o <= 1'b0;
			reg2_read_o <= 1'b0;
			reg1_addr_o <= `NOPRegAddr;
			reg2_addr_o <= `NOPRegAddr;
			imm <= 32'h0;
			link_addr_o <= `ZeroWord;
            branch_target_address_o <= `ZeroWord;
            branch_flag_o <= `NotBranch;
            next_inst_in_delayslot_o <= `NotInDelaySlot;						
	  end else begin
			aluop_o <= `EXE_NOP_OP;
			alusel_o <= `EXE_RES_NOP;
			wd_o <= inst_i[15:11];
			wreg_o <= `WriteDisable;
			instvalid <= `InstInvalid;	   
			reg1_read_o <= 1'b0;
			reg2_read_o <= 1'b0;
			reg1_addr_o <= inst_i[25:21];
			reg2_addr_o <= inst_i[20:16];		
			imm <= `ZeroWord;
			link_addr_o <= `ZeroWord;
            branch_target_address_o <= `ZeroWord;
            branch_flag_o <= `NotBranch;    
            next_inst_in_delayslot_o <= `NotInDelaySlot; 
            //异常处理			
            excepttype_is_syscall <= `False_v;
            excepttype_is_eret <= `False_v;
		    case (op)
                `EXE_SPECIAL_INST:		begin
                    case (op2)
                        5'b00000:			begin
                            case (op3)
                                `EXE_TEQ: begin
                                    wreg_o <= `WriteDisable;        aluop_o <= `EXE_TEQ_OP;
                                    alusel_o <= `EXE_RES_NOP;   reg1_read_o <= 1'b1;    reg2_read_o <= 1'b1;
                                    instvalid <= `InstValid;
                                end
                                `EXE_TGE: begin
                                    wreg_o <= `WriteDisable;        aluop_o <= `EXE_TGE_OP;
                                    alusel_o <= `EXE_RES_NOP;   reg1_read_o <= 1'b1;    reg2_read_o <= 1'b1;
                                    instvalid <= `InstValid;
                                end
                                `EXE_OR:	begin
                                    wreg_o <= `WriteEnable;		aluop_o <= `EXE_OR_OP;
                                    alusel_o <= `EXE_RES_LOGIC; 	reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
                                    instvalid <= `InstValid;	
                                    end  
                                `EXE_AND:	begin
                                    wreg_o <= `WriteEnable;		aluop_o <= `EXE_AND_OP;
                                    alusel_o <= `EXE_RES_LOGIC;	  reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;	
                                    instvalid <= `InstValid;	
                                    end  	
                                `EXE_XOR:	begin
                                    wreg_o <= `WriteEnable;		aluop_o <= `EXE_XOR_OP;
                                    alusel_o <= `EXE_RES_LOGIC;		reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;	
                                    instvalid <= `InstValid;	
                                    end  				
                                `EXE_NOR:	begin
                                    wreg_o <= `WriteEnable;		aluop_o <= `EXE_NOR_OP;
                                    alusel_o <= `EXE_RES_LOGIC;		reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;	
                                    instvalid <= `InstValid;	
                                    end 
                                `EXE_SRLV: begin
                                    wreg_o <= `WriteEnable;		aluop_o <= `EXE_SRL_OP;
                                    alusel_o <= `EXE_RES_SHIFT;		reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
                                    instvalid <= `InstValid;	
                                end 							
                                `EXE_SYNC: begin
                                    wreg_o <= `WriteDisable;		aluop_o <= `EXE_NOP_OP;
                                    alusel_o <= `EXE_RES_NOP;		reg1_read_o <= 1'b0;	reg2_read_o <= 1'b1;
                                    instvalid <= `InstValid;	
                                end	
                                `EXE_MOVN: begin
                                     aluop_o <= `EXE_MOVN_OP;
                                     alusel_o <= `EXE_RES_MOVE;   reg1_read_o <= 1'b1;    reg2_read_o <= 1'b1;
                                     instvalid <= `InstValid;
                                         if(reg2_o != `ZeroWord) begin
                                             wreg_o <= `WriteEnable;
                                         end else begin
                                             wreg_o <= `WriteDisable;
                                         end
                                end
                                `EXE_ADDU: begin
                                    wreg_o <= `WriteEnable;        aluop_o <= `EXE_ADDU_OP;
                                    alusel_o <= `EXE_RES_ARITHMETIC;        reg1_read_o <= 1'b1;    reg2_read_o <= 1'b1;
                                    instvalid <= `InstValid;    
                                end 
                                `EXE_JR: begin
                                    wreg_o <= `WriteDisable;        aluop_o <= `EXE_JR_OP;
                                    alusel_o <= `EXE_RES_JUMP_BRANCH;   reg1_read_o <= 1'b1;    reg2_read_o <= 1'b0;
                                    link_addr_o <= `ZeroWord;
                                  
                                    branch_target_address_o <= reg1_o;
                                    branch_flag_o <= `Branch;
                       
                                    next_inst_in_delayslot_o <= `InDelaySlot;
                                    instvalid <= `InstValid; 
                                end        
                                //异常处理
                                `EXE_SYSCALL: begin
                                    wreg_o <= `WriteDisable;        
                                    aluop_o <= `EXE_SYSCALL_OP;
                                    alusel_o <= `EXE_RES_NOP;   
                                    reg1_read_o <= 1'b0;   
                                    reg2_read_o <= 1'b0;
                                    instvalid <= `InstValid;
                                    excepttype_is_syscall<= `True_v;
                                end                                                                                           															  									
                                default:	begin
                                end
                             endcase
                             end
                        default: begin
                        end
                    endcase	
                    end	
                `EXE_SPECIAL2_INST:		begin
                    case ( op3 )
                        `EXE_CLO:    begin
                            wreg_o <= `WriteEnable;        aluop_o <= `EXE_CLO_OP;
                            alusel_o <= `EXE_RES_ARITHMETIC; reg1_read_o <= 1'b1;    reg2_read_o <= 1'b0;          
                            instvalid <= `InstValid;    
                         end
                          default:    begin
                          end
                   endcase 
                 end            								  
                `EXE_ORI:			begin                        //ORI指令
                    wreg_o <= `WriteEnable;		aluop_o <= `EXE_OR_OP;
                    alusel_o <= `EXE_RES_LOGIC; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
                    imm <= {16'h0, inst_i[15:0]};		wd_o <= inst_i[20:16];
                    instvalid <= `InstValid;	
                end
                `EXE_ANDI:			begin
                    wreg_o <= `WriteEnable;		aluop_o <= `EXE_AND_OP;
                    alusel_o <= `EXE_RES_LOGIC;	reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
                    imm <= {16'h0, inst_i[15:0]};		wd_o <= inst_i[20:16];		  	
                    instvalid <= `InstValid;	
                end	 	
                `EXE_XORI:			begin
                    wreg_o <= `WriteEnable;		aluop_o <= `EXE_XOR_OP;
                    alusel_o <= `EXE_RES_LOGIC;	reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
                    imm <= {16'h0, inst_i[15:0]};		wd_o <= inst_i[20:16];		  	
                    instvalid <= `InstValid;	
                end	 		
                `EXE_LUI:			begin
                    wreg_o <= `WriteEnable;		aluop_o <= `EXE_OR_OP;
                    alusel_o <= `EXE_RES_LOGIC; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
                    imm <= {inst_i[15:0], 16'h0};		wd_o <= inst_i[20:16];		  	
                    instvalid <= `InstValid;	
                end
    
                `EXE_ADDIU:            begin
                    wreg_o <= `WriteEnable;        aluop_o <= `EXE_ADDIU_OP;
                    alusel_o <= `EXE_RES_ARITHMETIC; reg1_read_o <= 1'b1;    reg2_read_o <= 1'b0;          
                    imm <= {{16{inst_i[15]}}, inst_i[15:0]};        wd_o <= inst_i[20:16];
                end
                `EXE_J:			begin
                    wreg_o <= `WriteDisable;        aluop_o <= `EXE_J_OP;
                    alusel_o <= `EXE_RES_JUMP_BRANCH; reg1_read_o <= 1'b0;    reg2_read_o <= 1'b0;
                    link_addr_o <= `ZeroWord;
                    branch_target_address_o <= {pc_plus_4[31:28], inst_i[25:0], 2'b00};
                    branch_flag_o <= `Branch;
                    next_inst_in_delayslot_o <= `InDelaySlot;              
                    instvalid <= `InstValid;    
                 end
                `EXE_JAL:            begin
                    wreg_o <= `WriteEnable;        aluop_o <= `EXE_JAL_OP;
                    alusel_o <= `EXE_RES_JUMP_BRANCH; reg1_read_o <= 1'b0;    reg2_read_o <= 1'b0;
                    wd_o <= 5'b11111;    
                    link_addr_o <= pc_plus_8 ;
                    branch_target_address_o <= {pc_plus_4[31:28], inst_i[25:0], 2'b00};
                    branch_flag_o <= `Branch;
                    next_inst_in_delayslot_o <= `InDelaySlot;              
                    instvalid <= `InstValid;    
                end
                `EXE_BEQ:            begin
                    wreg_o <= `WriteDisable;        aluop_o <= `EXE_BEQ_OP;
                    alusel_o <= `EXE_RES_JUMP_BRANCH; reg1_read_o <= 1'b1;    reg2_read_o <= 1'b1;
                    instvalid <= `InstValid;    
                    if(reg1_o == reg2_o) begin
                        branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
                        branch_flag_o <= `Branch;
                        next_inst_in_delayslot_o <= `InDelaySlot;              
                    end
                 end
                `EXE_BGTZ:            begin
                    wreg_o <= `WriteDisable;        aluop_o <= `EXE_BGTZ_OP;
                    alusel_o <= `EXE_RES_JUMP_BRANCH; reg1_read_o <= 1'b1;    reg2_read_o <= 1'b0;
                    instvalid <= `InstValid;    
                    if((reg1_o[31] == 1'b0) && (reg1_o != `ZeroWord)) begin
                        branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
                        branch_flag_o <= `Branch;
                        next_inst_in_delayslot_o <= `InDelaySlot;              
                    end
                end 
				`EXE_BNE:			begin
                    wreg_o <= `WriteDisable;        aluop_o <= `EXE_BNE_OP;
                    alusel_o <= `EXE_RES_JUMP_BRANCH; reg1_read_o <= 1'b1;    reg2_read_o <= 1'b1;
                    instvalid <= `InstValid;    
                    if(reg1_o != reg2_o) begin
                        branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
                        branch_flag_o <= `Branch;
                        next_inst_in_delayslot_o <= `InDelaySlot;              
                    end
                end                
				`EXE_LB:			begin
                    wreg_o <= `WriteEnable;        aluop_o <= `EXE_LB_OP;
                    alusel_o <= `EXE_RES_LOAD_STORE; reg1_read_o <= 1'b1;    reg2_read_o <= 1'b0;          
                    wd_o <= inst_i[20:16]; instvalid <= `InstValid;    
                end
                `EXE_LBU:            begin
                    wreg_o <= `WriteEnable;        aluop_o <= `EXE_LBU_OP;
                    alusel_o <= `EXE_RES_LOAD_STORE; reg1_read_o <= 1'b1;    reg2_read_o <= 1'b0;          
                    wd_o <= inst_i[20:16]; instvalid <= `InstValid;    
                end 
				`EXE_LW:			begin
                    wreg_o <= `WriteEnable;        aluop_o <= `EXE_LW_OP;
                    alusel_o <= `EXE_RES_LOAD_STORE; reg1_read_o <= 1'b1;    reg2_read_o <= 1'b0;          
                    wd_o <= inst_i[20:16]; instvalid <= `InstValid;    
                end
				`EXE_SB:			begin
                    wreg_o <= `WriteDisable;        aluop_o <= `EXE_SB_OP;
                    reg1_read_o <= 1'b1;    reg2_read_o <= 1'b1; instvalid <= `InstValid;    
                    alusel_o <= `EXE_RES_LOAD_STORE; 
                end  
				`EXE_SW:			begin
                    wreg_o <= `WriteDisable;        aluop_o <= `EXE_SW_OP;
                    reg1_read_o <= 1'b1;    reg2_read_o <= 1'b1; instvalid <= `InstValid;    
                    alusel_o <= `EXE_RES_LOAD_STORE; 
                end                                                                                                     				
                `EXE_PREF:			begin
                    wreg_o <= `WriteDisable;		aluop_o <= `EXE_NOP_OP;
                    alusel_o <= `EXE_RES_NOP; reg1_read_o <= 1'b0;	reg2_read_o <= 1'b0;	  	  	
                    instvalid <= `InstValid;	
                end										  	
		        default:			begin
		        end
	       endcase		  //case op
		  
           if (inst_i[31:21] == 11'b00000000000) begin
                if (op3 == `EXE_SLL) begin
                    wreg_o <= `WriteEnable;		aluop_o <= `EXE_SLL_OP;
                    alusel_o <= `EXE_RES_SHIFT; reg1_read_o <= 1'b0;	reg2_read_o <= 1'b1;	  	
                    imm[4:0] <= inst_i[10:6];		wd_o <= inst_i[15:11];
                    instvalid <= `InstValid;	
                end else if ( op3 == `EXE_SRL ) begin
                    wreg_o <= `WriteEnable;		aluop_o <= `EXE_SRL_OP;
                    alusel_o <= `EXE_RES_SHIFT; reg1_read_o <= 1'b0;	reg2_read_o <= 1'b1;	  	
                    imm[4:0] <= inst_i[10:6];		wd_o <= inst_i[15:11];
                    instvalid <= `InstValid;	
                end
           end
           if(inst_i == `EXE_ERET) begin
                wreg_o <= `WriteDisable;
                aluop_o <= `EXE_ERET_OP;
                alusel_o <= `EXE_RES_NOP;   
                reg1_read_o <= 1'b0;
                reg2_read_o <= 1'b0;
                instvalid <= `InstValid; 
                excepttype_is_eret<= `True_v;    
           end else if(inst_i[31:21] == 11'b01000000000 
            &&inst_i[10:0] == 11'b00000000000
           ) begin
                 aluop_o <= `EXE_MFC0_OP;
                 alusel_o <= `EXE_RES_MOVE;
                 wd_o <= inst_i[20:16];
                 wreg_o <= `WriteEnable;
                 instvalid <= `InstValid;       
                 reg1_read_o <= 1'b0;
                 reg2_read_o <= 1'b0;        
            end else if(inst_i[31:21] == 11'b01000000100
             &&inst_i[10:0] == 11'b00000000000
             ) begin
                 aluop_o <= `EXE_MTC0_OP;
                 alusel_o <= `EXE_RES_NOP;
                 wreg_o <= `WriteDisable;
                 instvalid <= `InstValid;       
                 reg1_read_o <= 1'b1;
                 reg1_addr_o <= inst_i[20:16];
                 reg2_read_o <= 1'b0;                    
             end
		  
		end       //if
	end         //always
	
	
	always @ (*) begin
        if(rst == `RstEnable) begin
            is_in_delayslot_o <= `NotInDelaySlot;
        end else begin
          is_in_delayslot_o <= is_in_delayslot_i;        
      end
    end	
         always @ (*) begin
            stallreq_for_reg1_loadrelate <= `NoStop;
            if (rst == `RstEnable) begin
                reg1_o <= 32'h0;
            end else if ((pre_inst_is_load == 1'b1) && (ex_wd_i == reg1_addr_o) &&(reg1_read_o==1'b1) )begin
                stallreq_for_reg1_loadrelate <= `Stop;
            
            end else if ((reg1_read_o == `ReadEnable) && (ex_wreg_i == `WriteEnable) && (ex_wd_i == reg1_addr_o)) begin
                reg1_o <= ex_wdata_i;
            end else if ((reg1_read_o == `ReadEnable) && (mem_wreg_i == `WriteEnable) && (mem_wd_i == reg1_addr_o)) begin
                reg1_o <= mem_wdata_i;
            end else if (reg1_read_o == `ReadEnable) begin
                reg1_o <= reg1_data_i;
            end else if (reg1_read_o == `ReadDisable) begin
                reg1_o <= imm; // 操作数为立即????????
            end else begin
                reg1_o <= 32'h0;
            end
        end
    
        // 确定????????要输出的操作????????2
        always @ (*) begin
            stallreq_for_reg2_loadrelate <= `NoStop;
            if (rst == `RstEnable) begin
                reg2_o <= 32'h0;
            end else if ((pre_inst_is_load == 1'b1) && (ex_wd_i == reg2_addr_o) &&(reg2_read_o==1'b1) )begin
                stallreq_for_reg2_loadrelate <= `Stop;
            end else if ((reg2_read_o == `ReadEnable) && (ex_wreg_i == `WriteEnable) && (ex_wd_i == reg2_addr_o)) begin
                reg2_o <= ex_wdata_i;
            end else if ((reg2_read_o == `ReadEnable) && (mem_wreg_i == `WriteEnable) && (mem_wd_i == reg2_addr_o)) begin
                reg2_o <= mem_wdata_i;
            end else if (reg2_read_o == `ReadEnable) begin
                reg2_o <= reg2_data_i;
            end else if (reg2_read_o == `ReadDisable) begin
                reg2_o <= imm; // 操作数为立即????????
            end else begin
                reg2_o <= 32'h0;
            end
        end
    
endmodule