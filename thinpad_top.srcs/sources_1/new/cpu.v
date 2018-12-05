//////////////////////////////////////////////////////////////////////
// Module:  cpu
// File:    cpu.v
// Author:  BaiReny
// E-mail:  bry6789@163.com
// Description: cpu�������Ķ����ļ�
// Revision: 1.0
//////////////////////////////////////////////////////////////////////

`include "defines.vh"

module cpu(

        input   wire                                                                            clk,
        input wire                                                                              rst,
            input wire              clk_uart,
        
    
    // base sram
    inout wire[31:0]        base_ram_data,
    output wire[19:0]       base_ram_addr,
    output wire             base_ram_ce_n,
    output wire             base_ram_oe_n,
    output wire             base_ram_we_n,
    output wire[3:0]        base_ram_be_n,
    
    // ext sram
    inout wire[31:0]        ext_ram_data,
    output wire[19:0]       ext_ram_addr,
    output wire             ext_ram_ce_n,
    output wire             ext_ram_oe_n,
    output wire             ext_ram_we_n,
    output wire[3:0]        ext_ram_be_n,
    
    // uart
    output TxD,
    input RxD,
    
    input wire[5:0] debug,
    output reg[`DebugBus] debugdata
);
    wire[`DebugBus] ifdebugdata ;
    wire[`DebugBus] iddebugdata ;
    wire[`DebugBus] exdebugdata ;
    wire[`DebugBus] memdebugdata ;
    wire[`DebugBus] wbdebugdata ;
    wire[`DebugBus] regdebugdata ;
    wire[`DebugBus] ctrldebugdata ;
    wire[`DebugBus] ex_memdebugdata ;
    wire[`DebugBus] busdebugdata;
    wire[`DebugBus] baseramdebugdata;
    wire[`DebugBus] extramdebugdata;
    wire[`DebugBus] memdebugdata_hi;
    wire[`DebugBus] cp0debugdata_r;
    wire[`DebugBus] cp0debugdata_w;
    
    //============== UART ==============
        wire                uart_RxD_data_ready;
        wire[7:0]           uart_RxD_data;
        wire                uart_rdn;
        wire                uart_TxDready;
        wire                uart_TxD_start;
        wire[7:0]           uart_TxD_data;
    
    
    always @(*) begin
        case(debug[4:0])
            6'b00000: begin
                debugdata <= ifdebugdata ;
            end
            6'b00001: begin
                debugdata <= iddebugdata ;
            end
            6'b00010: begin
                debugdata <= exdebugdata ;
            end
            6'b00011: begin
                debugdata <= memdebugdata ;     //�����ڴ��debug��Ϣ���������ʾ��8λ���������ݣ���������ʾ��16λ�������ַ
            end
            6'b10011: begin
                 debugdata <= memdebugdata_hi ; //�����ڴ��debug��Ϣ���������ʾ15-8λ���������ݣ���������ʾ��16λ�������ַ
            end
            6'b00100: begin
                debugdata <= wbdebugdata ;
            end           
            6'b00101: begin
                debugdata <= ctrldebugdata ;
            end
            6'b00110: begin
                debugdata <= busdebugdata;  //���ߵ�����Ϣ������������ַ�ĸ�8λ�������������ַ��16λ
            end
            6'b00111: begin
                debugdata <= baseramdebugdata;
            end
            6'b01000: begin
                debugdata <= extramdebugdata;
            end
            6'b01001: begin
                debugdata <= {base_ram_addr,base_ram_ce_n,base_ram_oe_n,base_ram_we_n,1'b0};
            end
            6'b01010: begin
                debugdata <= {base_ram_be_n,base_ram_data[19:0]};
            end
            6'b01011: begin
                debugdata <= {uart_TxD_data,uart_RxD_data,RxD,7'b0};
            end
             6'b01100: begin
                debugdata <= {cp0debugdata_w};
            end
             6'b01101: begin
                debugdata <= {cp0debugdata_r};
             end
            default: begin
                debugdata <= regdebugdata ;
            end
        endcase
    end
    
    //=========== Interrupt ===========
    wire[5:0]           int;
    wire                timer_int;
    
     //=========== IF =================
    wire[`InstAddrBus]  if_pc;
    wire                if_ce;
    wire[`InstBus]      if_inst;
      
        wire[`InstAddrBus] id_pc_i;
        wire[`InstBus] id_inst_i;
        
        //��������׶�IDģ��������ID/EXģ�������
        wire[`AluOpBus] id_aluop_o;
        wire[`AluSelBus] id_alusel_o;
        wire[`RegBus] id_reg1_o;
        wire[`RegBus] id_reg2_o;
        wire id_wreg_o;
        wire[`RegAddrBus] id_wd_o;
        wire id_is_in_delayslot_o;
        wire[`RegBus] id_link_address_o;
        wire[`RegBus] id_inst_o;
    
        wire[31:0] id_excepttype_o;
        wire[`RegBus] id_current_inst_address_o;
        
        //����ID/EXģ��������ִ�н׶�EXģ�������
        wire[`AluOpBus] ex_aluop_i;
        wire[`AluSelBus] ex_alusel_i;
        wire[`RegBus] ex_reg1_i;
        wire[`RegBus] ex_reg2_i;
        wire ex_wreg_i;
        wire[`RegAddrBus] ex_wd_i;
        wire ex_is_in_delayslot_i;      
        wire[`RegBus] ex_link_address_i;
        wire[`RegBus] ex_inst_i;
        
        wire[31:0] ex_excepttype_i;	
        wire[`RegBus] ex_current_inst_address_i;
        //����ִ�н׶�EXģ��������EX/MEMģ�������
        wire ex_wreg_o;
        wire[`RegAddrBus] ex_wd_o;
        wire[`RegBus] ex_wdata_o;
        wire[`AluOpBus] ex_aluop_o;
        wire[`RegBus] ex_mem_addr_o;
        wire[`RegBus] ex_reg1_o;
        wire[`RegBus] ex_reg2_o;    
    
        wire ex_cp0_reg_we_o;
        wire[4:0] ex_cp0_reg_write_addr_o;
        wire[`RegBus] ex_cp0_reg_data_o;     
        
        wire[31:0] ex_excepttype_o;
        wire[`RegBus] ex_current_inst_address_o;
        wire ex_is_in_delayslot_o;

        //����EX/MEMģ��������ô�׶�MEMģ�������
        wire mem_wreg_i;
        wire[`RegAddrBus] mem_wd_i;
        wire[`RegBus] mem_wdata_i;
        wire[`AluOpBus] mem_aluop_i;
        wire[`RegBus] mem_mem_addr_i;
        wire[`RegBus] mem_reg1_i;
        wire[`RegBus] mem_reg2_i;  
        
        wire mem_cp0_reg_we_i;
        wire[4:0] mem_cp0_reg_write_addr_i;
        wire[`RegBus] mem_cp0_reg_data_i;
        
        wire[31:0] mem_excepttype_i;	
        wire mem_is_in_delayslot_i;
        wire[`RegBus] mem_current_inst_address_i;
             

        //���ӷô�׶�MEMģ��������MEM/WBģ�������
        //for ram
        wire[`RegBus]       ram_mem_data_intomem;
        wire[`RegBus]       mem_ram_addr;
        wire                mem_ram_we;
        wire[3:0]           mem_ram_sel;
        wire[`RegBus]       mem_ram_data_intoram;
        wire                mem_ram_ce;
        
        wire mem_wreg_o;
        wire[`RegAddrBus] mem_wd_o;
        wire[`RegBus] mem_wdata_o;
        
        wire mem_cp0_reg_we_o;
        wire[4:0] mem_cp0_reg_write_addr_o;
        wire[`RegBus] mem_cp0_reg_data_o;
        
        wire[31:0] mem_excepttype_o;
        wire mem_is_in_delayslot_o;
        wire[`RegBus] mem_current_inst_address_o;    
        //����MEM/WBģ���������д�׶ε����� 
        wire wb_wreg_i;
        wire[`RegAddrBus] wb_wd_i;
        wire[`RegBus] wb_wdata_i;
        wire wb_cp0_reg_we_i;
        wire[4:0] wb_cp0_reg_write_addr_i;
        wire[`RegBus] wb_cp0_reg_data_i;    
        
        wire[31:0] wb_excepttype_i;
        wire wb_is_in_delayslot_i;
        wire[`RegBus] wb_current_inst_address_i;
        
        //��������׶�IDģ����ͨ�üĴ���Regfileģ��
        wire reg1_read;
        wire reg2_read;
        wire[`RegBus] reg1_data;
        wire[`RegBus] reg2_data;
        wire[`RegAddrBus] reg1_addr;
        wire[`RegAddrBus] reg2_addr;
        //�ӳٲ�
        wire is_in_delayslot_i;
        wire is_in_delayslot_o;
        wire next_inst_in_delayslot_o;
        wire id_branch_flag_o;
        wire[`RegBus] branch_target_address;
        //��ͣ
        wire[5:0] stall;
        wire stallreq_from_id;    
        wire stallreq_from_ex;
        wire stallreq_from_mem;
    
        wire stallreq_from_if;
    
        wire[31:0]          mmu_if_addr;
        wire[31:0]          mmu_mem_addr;
        
        //CP0���
        
        wire[`RegBus] cp0_data_o;
        wire[4:0] cp0_raddr_i;        
        //exception
        wire flush;
        wire[`RegBus] new_pc;
        wire[`RegBus] cp0_count;
        wire[`RegBus]    cp0_compare;
        wire[`RegBus]    cp0_status;
        wire[`RegBus]    cp0_cause;
        wire[`RegBus]    cp0_epc;
        wire[`RegBus]    cp0_config;
        wire[`RegBus]    cp0_prid;
        wire[`RegBus] latest_epc;
        
      
  //pc_reg����
        pc_reg pc_reg0(
                .clk(clk),
                .rst(rst),
                .stall(stall),
                .flush(flush),
                .new_pc(new_pc),
                .branch_flag_i(id_branch_flag_o),
                .branch_target_address_i(branch_target_address),    
                .pc(if_pc),
                .ce(if_ce)      
                        
        );
        
//  assign rom_addr_o = pc;

  //IF/IDģ������
        if_id if_id0(
                .clk(clk),
                .rst(rst),
                .stall(stall),
                .flush(flush),
                .if_pc(if_pc),
                .if_inst(if_inst),
                .id_pc(id_pc_i),
                .id_inst(id_inst_i),
                .debugdata(ifdebugdata)         
        );
        
        //����׶�IDģ��
        id id0(
                .rst(rst),
                .pc_i(id_pc_i),
                .inst_i(id_inst_i),

                .ex_aluop_i(ex_aluop_o),
        
                .reg1_data_i(reg1_data),
                .reg2_data_i(reg2_data),

            //����ִ�н׶ε�ָ��Ҫд���Ŀ�ļĴ�����Ϣ���˴����RAW���ݳ�ͻ
                .ex_wreg_i(ex_wreg_o),
                .ex_wdata_i(ex_wdata_o),
                .ex_wd_i(ex_wd_o),

            //���ڷô�׶ε�ָ��Ҫд���Ŀ�ļĴ�����Ϣ���˴����RAW���ݳ�ͻ
                .mem_wreg_i(mem_wreg_o),
                .mem_wdata_i(mem_wdata_o),
                .mem_wd_i(mem_wd_o),
            //�ӳٲ�
                .is_in_delayslot_i(is_in_delayslot_i),

                //�͵�regfile����Ϣ
                .reg1_read_o(reg1_read),
                .reg2_read_o(reg2_read),          

                .reg1_addr_o(reg1_addr),
                .reg2_addr_o(reg2_addr), 
          
                //�͵�ID/EXģ�����Ϣ
                .aluop_o(id_aluop_o),
                .alusel_o(id_alusel_o),
                .reg1_o(id_reg1_o),
                .reg2_o(id_reg2_o),
                .wd_o(id_wd_o),
                .wreg_o(id_wreg_o),
                .inst_o(id_inst_o),
                
                .excepttype_o(id_excepttype_o),
                
           .next_inst_in_delayslot_o(next_inst_in_delayslot_o), 
           .branch_flag_o(id_branch_flag_o),
           .branch_target_address_o(branch_target_address),       
           .link_addr_o(id_link_address_o),
       
            .is_in_delayslot_o(id_is_in_delayslot_o),
            .current_inst_address_o(id_current_inst_address_o),
                
            .stallreq(stallreq_from_id)
        );

  //ͨ�üĴ���Regfile����
        regfile regfile1(
                .clk (clk),
                .rst (rst),
                .we     (wb_wreg_i),
                .waddr (wb_wd_i),
                .wdata (wb_wdata_i),
                .re1 (reg1_read),
                .raddr1 (reg1_addr),
                .rdata1 (reg1_data),
                .re2 (reg2_read),
                .raddr2 (reg2_addr),
                .rdata2 (reg2_data)
        );

        //ID/EXģ��
        id_ex id_ex0(
                .clk(clk),
                .rst(rst),
                .stall(stall),
                .flush(flush),
                //������׶�IDģ�鴫�ݵ���Ϣ
                .id_aluop(id_aluop_o),
                .id_alusel(id_alusel_o),
                .id_reg1(id_reg1_o),
                .id_reg2(id_reg2_o),
                .id_wd(id_wd_o),
                .id_wreg(id_wreg_o),
                .id_link_address(id_link_address_o),
                .id_is_in_delayslot(id_is_in_delayslot_o),
                .next_inst_in_delayslot_i(next_inst_in_delayslot_o),
                .id_inst(id_inst_o),             
                
                .id_excepttype(id_excepttype_o),
                .id_current_inst_address(id_current_inst_address_o),               
        
                //���ݵ�ִ�н׶�EXģ�����Ϣ
                .ex_aluop(ex_aluop_i),
                .ex_alusel(ex_alusel_i),
                .ex_reg1(ex_reg1_i),
                .ex_reg2(ex_reg2_i),
                .ex_wd(ex_wd_i),
                .ex_wreg(ex_wreg_i),
                .ex_link_address(ex_link_address_i),
                .ex_is_in_delayslot(ex_is_in_delayslot_i),
                .is_in_delayslot_o(is_in_delayslot_i),
                .ex_inst(ex_inst_i),
                
                .ex_excepttype(ex_excepttype_i),
                .ex_current_inst_address(ex_current_inst_address_i),
                        
                .debugdata(iddebugdata)         
        );              
        
        //EXģ��
        ex ex0(
                .rst(rst),
        
                //�͵�ִ�н׶�EXģ�����Ϣ
                .aluop_i(ex_aluop_i),
                .alusel_i(ex_alusel_i),
                .reg1_i(ex_reg1_i),
                .reg2_i(ex_reg2_i),
                .wd_i(ex_wd_i),
                .wreg_i(ex_wreg_i),
                .inst_i(ex_inst_i),
                
                .link_address_i(ex_link_address_i),
                .is_in_delayslot_i(ex_is_in_delayslot_i),     
                
                .excepttype_i(ex_excepttype_i),
                .current_inst_address_i(ex_current_inst_address_i),          
          
                 //EXģ��������EX/MEMģ����Ϣ
                .wd_o(ex_wd_o),
                .wreg_o(ex_wreg_o),
                .wdata_o(ex_wdata_o),
                
                .aluop_o(ex_aluop_o),
                .mem_addr_o(ex_mem_addr_o),
                .reg2_o(ex_reg2_o), 
                            
                  //�ô�׶ε�ָ���Ƿ�ҪдCP0����������������
                .mem_cp0_reg_we(mem_cp0_reg_we_o),
                .mem_cp0_reg_write_addr(mem_cp0_reg_write_addr_o),
                .mem_cp0_reg_data(mem_cp0_reg_data_o),

                .wb_cp0_reg_we(wb_cp0_reg_we_i), 
                .wb_cp0_reg_write_addr(wb_cp0_reg_write_addr_i),
                .wb_cp0_reg_data(wb_cp0_reg_data_i),  
                
                .cp0_reg_data_i(cp0_data_o),
                .cp0_reg_read_addr_o(cp0_raddr_i),     
                
                //����һ��ˮ�����ݣ�����дCP0�еļĴ���
                .cp0_reg_we_o(ex_cp0_reg_we_o),
                .cp0_reg_write_addr_o(ex_cp0_reg_write_addr_o),
                .cp0_reg_data_o(ex_cp0_reg_data_o),
                
                .excepttype_o(ex_excepttype_o),
                .is_in_delayslot_o(ex_is_in_delayslot_o),
                .current_inst_address_o(ex_current_inst_address_o),    
                
                .stallreq(stallreq_from_id)
                
        );

  //EX/MEMģ��
  ex_mem ex_mem0(
                .clk(clk),
                .rst(rst),
                .stall(stall),
                .flush(flush),
                
                //����ִ�н׶�EXģ�����Ϣ 
                .ex_wd(ex_wd_o),
                .ex_wreg(ex_wreg_o),
                .ex_wdata(ex_wdata_o),
                
                .ex_aluop(ex_aluop_o),
                .ex_mem_addr(ex_mem_addr_o),
                .ex_reg2(ex_reg2_o),
                
                .ex_cp0_reg_we(ex_cp0_reg_we_o),
                .ex_cp0_reg_write_addr(ex_cp0_reg_write_addr_o),
                .ex_cp0_reg_data(ex_cp0_reg_data_o),
                
                .ex_excepttype(ex_excepttype_o),
                .ex_is_in_delayslot(ex_is_in_delayslot_o),
                .ex_current_inst_address(ex_current_inst_address_o),
        

                //�͵��ô�׶�MEMģ�����Ϣ
                .mem_wd(mem_wd_i),
                .mem_wreg(mem_wreg_i),
                .mem_wdata(mem_wdata_i),
               
                .mem_cp0_reg_we(mem_cp0_reg_we_i),
                .mem_cp0_reg_write_addr(mem_cp0_reg_write_addr_i),
                .mem_cp0_reg_data(mem_cp0_reg_data_i),
                
                .mem_aluop(mem_aluop_i),
                .mem_mem_addr(mem_mem_addr_i),
                .mem_reg2(mem_reg2_i),
                
                .mem_excepttype(mem_excepttype_i),
                .mem_is_in_delayslot(mem_is_in_delayslot_i),
                .mem_current_inst_address(mem_current_inst_address_i),
                
                .debugdata(exdebugdata)                                             
        );
        
  //MEMģ������
        mem mem0(
                .rst(rst),
        
                //����EX/MEMģ�����Ϣ 
                .wd_i(mem_wd_i),
                .wreg_i(mem_wreg_i),
                .wdata_i(mem_wdata_i),
                
                .aluop_i(mem_aluop_i),
                .mem_addr_i(mem_mem_addr_i),
                .reg2_i(mem_reg2_i),        
                //����memory����Ϣ
                .mem_data_i(ram_mem_data_intomem),
                
                .cp0_reg_we_i(mem_cp0_reg_we_i),
                .cp0_reg_write_addr_i(mem_cp0_reg_write_addr_i),
                .cp0_reg_data_i(mem_cp0_reg_data_i),
                
                .excepttype_i(mem_excepttype_i),
                .is_in_delayslot_i(mem_is_in_delayslot_i),
                .current_inst_address_i(mem_current_inst_address_i),
                
                .cp0_status_i(cp0_status),
                .cp0_cause_i(cp0_cause),
                .cp0_epc_i(cp0_epc),
                
                //��д�׶ε�ָ���Ƿ�ҪдCP0����������������
                .wb_cp0_reg_we(wb_cp0_reg_we_i),
                .wb_cp0_reg_write_addr(wb_cp0_reg_write_addr_i),
                .wb_cp0_reg_data(wb_cp0_reg_data_i),
                
                 .cp0_reg_we_o(mem_cp0_reg_we_o),
                 .cp0_reg_write_addr_o(mem_cp0_reg_write_addr_o),
                 .cp0_reg_data_o(mem_cp0_reg_data_o),
                //�͵�MEM/WBģ�����Ϣ
                .wd_o(mem_wd_o),
                .wreg_o(mem_wreg_o),
                .wdata_o(mem_wdata_o),
                
                //�͵�memory����Ϣ
                .mem_addr_o(mem_ram_addr),
                .mem_we_o(mem_ram_we),
                .mem_sel_o(mem_ram_sel),
                .mem_data_o(mem_ram_data_intoram),
                .mem_ce_o(mem_ram_ce),
                
                .excepttype_o(mem_excepttype_o),
                .cp0_epc_o(latest_epc),
                .is_in_delayslot_o(mem_is_in_delayslot_o),
                .current_inst_address_o(mem_current_inst_address_o),
           
                .debugdata(memdebugdata),
                .debugdatanew(memdebugdata_hi) 
        );

  //MEM/WBģ��
        mem_wb mem_wb0(
                .clk(clk),
                .rst(rst),
                .stall(stall),
                .flush(flush),

                //���Էô�׶�MEMģ�����Ϣ        
                .mem_wd(mem_wd_o),
                .mem_wreg(mem_wreg_o),
                .mem_wdata(mem_wdata_o),
                
                 .mem_cp0_reg_we(mem_cp0_reg_we_o),
                 .mem_cp0_reg_write_addr(mem_cp0_reg_write_addr_o),
                 .mem_cp0_reg_data(mem_cp0_reg_data_o),  
        
                //�͵���д�׶ε���Ϣ
                .wb_wd(wb_wd_i),
                .wb_wreg(wb_wreg_i),
                .wb_wdata(wb_wdata_i),
                
                .wb_cp0_reg_we(wb_cp0_reg_we_i),
                .wb_cp0_reg_write_addr(wb_cp0_reg_write_addr_i),
                .wb_cp0_reg_data(wb_cp0_reg_data_i),        
                
                .debugdata(wbdebugdata)      
                                                                                
        );
        ctrl ctrl0(
        .rst(rst),    
        .excepttype_i(mem_excepttype_o),
        .cp0_epc_i(latest_epc),
        .stallreq_from_id(stallreq_from_id),   
      //����ִ�н׶ε���ͣ����
        .stallreq_from_ex(stallreq_from_ex),
        //�����ڴ����ͣ
        .stallreq_from_mem(stallreq_from_mem),
        .stallreq_from_if(stallreq_from_if),
        .new_pc(new_pc),
        .flush(flush),
        .stall(stall),
        .debugdata(ctrldebugdata)          
    );  
    
    mmu mmu_if(
        .addr_i(if_pc),
        .addr_o(mmu_if_addr)
);
        
    mmu mmu_mem(
        .addr_i(mem_ram_addr),
        .addr_o(mmu_mem_addr)
    );
    
    wire base_ram_ce;
    wire base_ram_we;
    wire[19:0] base_ram_addr_bus;
    wire[31:0] base_ram_data_o;
    wire[31:0] base_ram_data_i;
    wire[3:0] base_ram_sel;
    
    wire ext_ram_ce;
    wire ext_ram_we;
    wire[19:0] ext_ram_addr_bus;
    wire[31:0] ext_ram_data_o;
    wire[31:0] ext_ram_data_i;
    wire[3:0] ext_ram_sel;
    
    
    
bus bus0(
        .clk(clk),
        .rst(rst),

        .stall_i(stall),
//        .flush_i(flush),

        .if_ce_i(if_ce),
        .if_addr_i(mmu_if_addr),
        .if_data_o(if_inst),
        .if_stallreq_o(stallreq_from_if),
        
        .mem_ce_i(mem_ram_ce),
        .mem_data_i(mem_ram_data_intoram),
        .mem_addr_i(mmu_mem_addr),
        .mem_we_i(mem_ram_we),
        .mem_sel_i(mem_ram_sel),
        .mem_data_o(ram_mem_data_intomem),
        .mem_stallreq_o(stallreq_from_mem),
        .base_ram_ce_o(base_ram_ce),
        .base_ram_we_o(base_ram_we),
        .base_ram_addr_o(base_ram_addr_bus),
        .base_ram_sel_o(base_ram_sel),
        .base_ram_data_o(base_ram_data_o),
        .base_ram_data_i(base_ram_data_i),
        .ext_ram_ce_o(ext_ram_ce),
        .ext_ram_we_o(ext_ram_we),
        .ext_ram_addr_o(ext_ram_addr_bus),
        .ext_ram_sel_o(ext_ram_sel),
        .ext_ram_data_o(ext_ram_data_o),
        .ext_ram_data_i(ext_ram_data_i),
        .busdebugdata(busdebugdata),
        
//        .vga_data_o(vga_wdata),
//        .vga_ce_o(vga_ce),
//        .vga_we_o(vga_we),
//        .vga_addr_o(vga_waddr),
        // ======= debug ===========
        .pc(if_pc),
//        .button_buff(btnbuff),


        .uart_RxD_dataready_i(uart_RxD_data_ready),
        .uart_RxD_data_i(uart_RxD_data),
        .uart_RxD_rdn_o(uart_rdn),
        .uart_TxD_ready_i(uart_TxDready),
        .uart_TxD_start_o(uart_TxD_start),
        .uart_TxD_data_o(uart_TxD_data)

    );
    
    sram_controller ext_sram_controller(
            .clk(clk),
            .addr_i(ext_ram_addr_bus),
            .data_i(ext_ram_data_o),
            .ce_i(ext_ram_ce),
            .we_i(ext_ram_we),
            .sel_i(ext_ram_sel),
            .data_o(ext_ram_data_i),
    
            .sram_data(ext_ram_data),
            .sram_addr(ext_ram_addr),
            .sram_ce_n(ext_ram_ce_n),
            .sram_oe_n(ext_ram_oe_n),
            .sram_we_n(ext_ram_we_n),
            .sram_be_n(ext_ram_be_n),
            .debugdata(extramdebugdata),
            
            // ====== debug ======
            .pc(if_pc),
            .inst(if_inst),
            .stall(stall)
                    
        );
    
    sram_controller base_sram_controller(
        .clk(clk),
        .addr_i(base_ram_addr_bus),
        .data_i(base_ram_data_o),
        .ce_i(base_ram_ce),
        .we_i(base_ram_we),
        .sel_i(base_ram_sel),
        .data_o(base_ram_data_i),

        .sram_data(base_ram_data),
        .sram_addr(base_ram_addr),
        .sram_ce_n(base_ram_ce_n),
        .sram_oe_n(base_ram_oe_n),
        .sram_we_n(base_ram_we_n),
        .sram_be_n(base_ram_be_n),
        .debugdata(baseramdebugdata),
        // ====== debug ======
        .pc(if_pc),
        .inst(if_inst),
        .stall(stall)
                
    );


    async_transmitter #(.ClkFrequency(30000000),.Baud(9600))
        async_transmitter0(
        .clk(clk_uart),
        .TxD_start(uart_TxD_start),
        .TxD_data(uart_TxD_data),
        .TxD_ready(uart_TxDready),
        .TxD(TxD)
//        .over(real_over)
    );

    async_receiver #(.ClkFrequency(30000000),.Baud(9600))
        async_receiver0(
        .clk(clk_uart),
        .RxD(RxD),
        .RxD_data_ready(uart_RxD_data_ready),
        .RxD_data(uart_RxD_data),
        .rdn(uart_rdn)
    );
    
    assign int = {3'b0, uart_RxD_data_ready, 1'b0, timer_int};
   cp0_reg cp0_reg0(
            .clk(clk),
            .rst(rst),
            
            .we_i(wb_cp0_reg_we_i),
            .waddr_i(wb_cp0_reg_write_addr_i),
            .raddr_i(cp0_raddr_i),
            .data_i(wb_cp0_reg_data_i),
            
            .excepttype_i(mem_excepttype_o),
            .int_i(int),
            .current_inst_addr_i(mem_current_inst_address_o),
            .is_in_delayslot_i(mem_is_in_delayslot_o),
            
            .data_o(cp0_data_o),
            .count_o(cp0_count),
                    .compare_o(cp0_compare),
                    .status_o(cp0_status),
                    .cause_o(cp0_cause),
                    .epc_o(cp0_epc),
                    .config_o(cp0_config),
            .prid_o(cp0_prid),
            
            
            .timer_int_o(timer_int),
            .debugdata_r(cp0debugdata_r),
            .debugdata_w(cp0debugdata_w)
        );
endmodule