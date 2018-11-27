//////////////////////////////////////////////////////////////////////
// Module:  cpu
// File:    cpu.v
// Author:  BaiReny
// E-mail:  bry6789@163.com
// Description: cpu处理器的顶层文件
// Revision: 1.0
//////////////////////////////////////////////////////////////////////

`include "defines.vh"

module cpu(

        input   wire                                                                            clk,
        input wire                                                                              rst,
        
 
//      input wire[`RegBus]           rom_data_i,
//      output wire[`RegBus]           rom_addr_o,
//      output wire                    rom_ce_o,
//    //连接数据存储器data_ram
//    input wire[`RegBus]           ram_data_i,
//    output wire[`RegBus]           ram_addr_o,
//    output wire[`RegBus]           ram_data_o,
//    output wire                    ram_we_o,
//    output wire[3:0]               ram_sel_o,
//    output wire[3:0]               ram_ce_o,
    
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
    always @(*) begin
        case(debug[5:0])
            6'b000000: begin
                debugdata <= ifdebugdata ;
            end
            6'b000001: begin
                debugdata <= iddebugdata ;
            end
            6'b000010: begin
                debugdata <= exdebugdata ;
            end
            6'b000011: begin
                debugdata <= memdebugdata ;
            end
            6'b000100: begin
                debugdata <= wbdebugdata ;
            end           
            6'b000101: begin
                debugdata <= ctrldebugdata ;
            end
            6'b000110: begin
                debugdata <= busdebugdata;
            end
            default: begin
                debugdata <= regdebugdata ;
            end
        endcase
    end
    
    
     //=========== IF =================
    wire[`InstAddrBus]  if_pc;
    wire                if_ce;
    wire[`InstBus]      if_inst;
      
        wire[`InstAddrBus] id_pc_i;
        wire[`InstBus] id_inst_i;
        
        //连接译码阶段ID模块的输出与ID/EX模块的输入
        wire[`AluOpBus] id_aluop_o;
        wire[`AluSelBus] id_alusel_o;
        wire[`RegBus] id_reg1_o;
        wire[`RegBus] id_reg2_o;
        wire id_wreg_o;
        wire[`RegAddrBus] id_wd_o;
    wire id_is_in_delayslot_o;
    wire[`RegBus] id_link_address_o;
    wire[`RegBus] id_inst_o;
        
        //连接ID/EX模块的输出与执行阶段EX模块的输入
        wire[`AluOpBus] ex_aluop_i;
        wire[`AluSelBus] ex_alusel_i;
        wire[`RegBus] ex_reg1_i;
        wire[`RegBus] ex_reg2_i;
        wire ex_wreg_i;
        wire[`RegAddrBus] ex_wd_i;
        wire ex_is_in_delayslot_i;      
    wire[`RegBus] ex_link_address_i;
    wire[`RegBus] ex_inst_i;
        
        //连接执行阶段EX模块的输出与EX/MEM模块的输入
        wire ex_wreg_o;
        wire[`RegAddrBus] ex_wd_o;
        wire[`RegBus] ex_wdata_o;
        wire[`AluOpBus] ex_aluop_o;
    wire[`RegBus] ex_mem_addr_o;
    wire[`RegBus] ex_reg1_o;
    wire[`RegBus] ex_reg2_o;    

        //连接EX/MEM模块的输出与访存阶段MEM模块的输入
        wire mem_wreg_i;
        wire[`RegAddrBus] mem_wd_i;
        wire[`RegBus] mem_wdata_i;
        wire[`AluOpBus] mem_aluop_i;
    wire[`RegBus] mem_mem_addr_i;
    wire[`RegBus] mem_reg1_i;
    wire[`RegBus] mem_reg2_i;           

        //连接访存阶段MEM模块的输出与MEM/WB模块的输入
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

        
        //连接MEM/WB模块的输出与回写阶段的输入 
        wire wb_wreg_i;
        wire[`RegAddrBus] wb_wd_i;
        wire[`RegBus] wb_wdata_i;
        
        //连接译码阶段ID模块与通用寄存器Regfile模块
    wire reg1_read;
    wire reg2_read;
    wire[`RegBus] reg1_data;
    wire[`RegBus] reg2_data;
    wire[`RegAddrBus] reg1_addr;
    wire[`RegAddrBus] reg2_addr;
    //延迟槽
    wire is_in_delayslot_i;
    wire is_in_delayslot_o;
    wire next_inst_in_delayslot_o;
    wire id_branch_flag_o;
    wire[`RegBus] branch_target_address;
    //暂停
    wire[5:0] stall;
    wire stallreq_from_id;    
    wire stallreq_from_ex;
    wire stallreq_from_mem;
    wire stallreq_from_if;

    wire[31:0]          mmu_if_addr;
    wire[31:0]          mmu_mem_addr;
  
  //pc_reg例化
        pc_reg pc_reg0(
                .clk(clk),
                .rst(rst),
                .stall(stall),
                .branch_flag_i(id_branch_flag_o),
        .branch_target_address_i(branch_target_address),    
                .pc(if_pc),
                .ce(if_ce)      
                        
        );
        
//  assign rom_addr_o = pc;

  //IF/ID模块例化
        if_id if_id0(
                .clk(clk),
                .rst(rst),
                .stall(stall),
                .if_pc(if_pc),
                .if_inst(if_inst),
                .id_pc(id_pc_i),
                .id_inst(id_inst_i),
                .debugdata(ifdebugdata)         
        );
        
        //译码阶段ID模块
        id id0(
                .rst(rst),
                .pc_i(id_pc_i),
                .inst_i(id_inst_i),

        .ex_aluop_i(ex_aluop_o),
        
                .reg1_data_i(reg1_data),
                .reg2_data_i(reg2_data),

            //处于执行阶段的指令要写入的目的寄存器信息，此处解决RAW数据冲突
                .ex_wreg_i(ex_wreg_o),
                .ex_wdata_i(ex_wdata_o),
                .ex_wd_i(ex_wd_o),

            //处于访存阶段的指令要写入的目的寄存器信息，此处解决RAW数据冲突
                .mem_wreg_i(mem_wreg_o),
                .mem_wdata_i(mem_wdata_o),
                .mem_wd_i(mem_wd_o),
            //延迟槽
                .is_in_delayslot_i(is_in_delayslot_i),

                //送到regfile的信息
                .reg1_read_o(reg1_read),
                .reg2_read_o(reg2_read),          

                .reg1_addr_o(reg1_addr),
                .reg2_addr_o(reg2_addr), 
          
                //送到ID/EX模块的信息
                .aluop_o(id_aluop_o),
                .alusel_o(id_alusel_o),
                .reg1_o(id_reg1_o),
                .reg2_o(id_reg2_o),
                .wd_o(id_wd_o),
                .wreg_o(id_wreg_o),
                .inst_o(id_inst_o),
                
           .next_inst_in_delayslot_o(next_inst_in_delayslot_o), 
       .branch_flag_o(id_branch_flag_o),
       .branch_target_address_o(branch_target_address),       
       .link_addr_o(id_link_address_o),
       
       .is_in_delayslot_o(id_is_in_delayslot_o),
                
                .stallreq(stallreq_from_id)
        );

  //通用寄存器Regfile例化
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

        //ID/EX模块
        id_ex id_ex0(
                .clk(clk),
                .rst(rst),
                .stall(stall),
                
                //从译码阶段ID模块传递的信息
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
        
                //传递到执行阶段EX模块的信息
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
        .debugdata(iddebugdata)         
        );              
        
        //EX模块
        ex ex0(
                .rst(rst),
        
                //送到执行阶段EX模块的信息
                .aluop_i(ex_aluop_i),
                .alusel_i(ex_alusel_i),
                .reg1_i(ex_reg1_i),
                .reg2_i(ex_reg2_i),
                .wd_i(ex_wd_i),
                .wreg_i(ex_wreg_i),
                .inst_i(ex_inst_i),
                .link_address_i(ex_link_address_i),
        .is_in_delayslot_i(ex_is_in_delayslot_i),               
          
          //EX模块的输出到EX/MEM模块信息
                .wd_o(ex_wd_o),
                .wreg_o(ex_wreg_o),
                .wdata_o(ex_wdata_o),
                
                .aluop_o(ex_aluop_o),
        .mem_addr_o(ex_mem_addr_o),
        .reg2_o(ex_reg2_o),             
                        
                .stallreq(stallreq_from_id)
                
        );

  //EX/MEM模块
  ex_mem ex_mem0(
                .clk(clk),
                .rst(rst),
                .stall(stall),
          
                //来自执行阶段EX模块的信息 
                .ex_wd(ex_wd_o),
                .ex_wreg(ex_wreg_o),
                .ex_wdata(ex_wdata_o),
                
                .ex_aluop(ex_aluop_o),
        .ex_mem_addr(ex_mem_addr_o),
        .ex_reg2(ex_reg2_o),
        

                //送到访存阶段MEM模块的信息
                .mem_wd(mem_wd_i),
                .mem_wreg(mem_wreg_i),
                .mem_wdata(mem_wdata_i),
                
            .mem_aluop(mem_aluop_i),
        .mem_mem_addr(mem_mem_addr_i),
        .mem_reg2(mem_reg2_i),
        .debugdata(exdebugdata)
                                                        
        );
        
  //MEM模块例化
        mem mem0(
                .rst(rst),
        
                //来自EX/MEM模块的信息 
                .wd_i(mem_wd_i),
                .wreg_i(mem_wreg_i),
                .wdata_i(mem_wdata_i),
                
                .aluop_i(mem_aluop_i),
        .mem_addr_i(mem_mem_addr_i),
        .reg2_i(mem_reg2_i),            
    
        //来自memory的信息
       // .mem_data_i(ram_data_i),
        .mem_data_i(ram_mem_data_intomem),
                //送到MEM/WB模块的信息
                .wd_o(mem_wd_o),
                .wreg_o(mem_wreg_o),
                .wdata_o(mem_wdata_o),
                
                //送到memory的信息
        .mem_addr_o(mem_ram_addr),
        .mem_we_o(mem_ram_we),
        .mem_sel_o(mem_ram_sel),
        .mem_data_o(mem_ram_data_intoram),
        .mem_ce_o(mem_ram_ce),
        .debugdata(memdebugdata)     
        );

  //MEM/WB模块
        mem_wb mem_wb0(
                .clk(clk),
                .rst(rst),
                .stall(stall),

                //来自访存阶段MEM模块的信息        
                .mem_wd(mem_wd_o),
                .mem_wreg(mem_wreg_o),
                .mem_wdata(mem_wdata_o),
        
                //送到回写阶段的信息
                .wb_wd(wb_wd_i),
                .wb_wreg(wb_wreg_i),
                .wb_wdata(wb_wdata_i),
                .debugdata(wbdebugdata)      
                                                                                
        );
        ctrl ctrl0(
        .rst(rst),    
        .stallreq_from_id(stallreq_from_id),   
      //来自执行阶段的暂停请求
        .stallreq_from_ex(stallreq_from_ex),
        //来自内存的暂停
        .stallreq_from_mem(stallreq_from_mem),
        .stallreq_from_if(stallreq_from_if),
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
    wire[19:0] base_ram_addr;
    wire[31:0] base_ram_data_o;
    wire[31:0] base_ram_data_i;
    wire[3:0] base_ram_sel;
    
    wire ext_ram_ce;
    wire ext_ram_we;
    wire[19:0] ext_ram_addr;
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
        .base_ram_addr_o(base_ram_addr),
        .base_ram_sel_o(base_ram_sel),
        .base_ram_data_o(base_ram_data_o),
        .base_ram_data_i(base_ram_data_i),
        .ext_ram_ce_o(ext_ram_ce),
        .ext_ram_we_o(ext_ram_we),
        .ext_ram_addr_o(ext_ram_addr),
        .ext_ram_sel_o(ext_ram_sel),
        .ext_ram_data_o(ext_ram_data_o),
        .ext_ram_data_i(ext_ram_data_i),
        .busdebugdata(busdebugdata),
        
//        .vga_data_o(vga_wdata),
//        .vga_ce_o(vga_ce),
//        .vga_we_o(vga_we),
//        .vga_addr_o(vga_waddr),
//        .touch_btn(touch_btn),
        // ======= debug ===========
        .pc(if_pc)
//        .button_buff(btnbuff),


//        .uart_RxD_dataready_i(uart_RxD_data_ready),
//        .uart_RxD_data_i(uart_RxD_data),
//        .uart_RxD_rdn_o(uart_rdn),
//        .uart_TxD_ready_i(uart_TxDready),
//        .uart_TxD_start_o(uart_TxD_start),
//        .uart_TxD_data_o(uart_TxD_data)

    );
    
        sram_controller ext_sram_controller(
            .clk(clk),
            .addr_i(ext_ram_addr),
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
            
            // ====== debug ======
            .pc(if_pc),
            .inst(if_inst),
            .stall(stall)
                    
        );
    
    sram_controller base_sram_controller(
        .clk(clk),
        .addr_i(base_ram_addr),
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
        // ====== debug ======
        .pc(if_pc),
        .inst(if_inst),
        .stall(stall)
                
    );
endmodule