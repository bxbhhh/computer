`timescale 1ns / 1ps
`include "defines.vh"

module bus(
    input wire        clk,
    input wire        rst,
    // ctrl
    input wire[5:0]     stall_i,
    // input wire          flush_i,

    input wire          if_ce_i,
    input wire[`RegBus] if_addr_i,
    output reg[`RegBus] if_data_o,
    output reg          if_stallreq_o,

    input wire          mem_ce_i,
    input wire[`RegBus] mem_data_i,
    input wire[`RegBus] mem_addr_i,
    input wire          mem_we_i,
    input wire[3:0]     mem_sel_i,
    output reg[`RegBus] mem_data_o,
    
    output reg          mem_stallreq_o,
    //UART
    input wire uart_RxD_dataready_i,
    input wire[7:0] uart_RxD_data_i,
    output reg uart_RxD_rdn_o,
    
    input wire uart_TxD_ready_i,
    output reg uart_TxD_start_o,
    output reg[7:0] uart_TxD_data_o,


    // base sram
    output reg          base_ram_ce_o,
    output reg          base_ram_we_o,
    output reg[19:0]    base_ram_addr_o,
    output reg[`RegBus] base_ram_data_o,
    output reg[3:0]     base_ram_sel_o,
    input wire[`RegBus] base_ram_data_i,
    
    // ext sram 
    output reg          ext_ram_ce_o,
    output reg          ext_ram_we_o,
    output reg[19:0]    ext_ram_addr_o,
    output reg[`RegBus] ext_ram_data_o,
    output reg[3:0]     ext_ram_sel_o,
    input wire[`RegBus] ext_ram_data_i,

    // vga
    output reg[31:0]     vga_data_o,
    output reg          vga_ce_o,
    output reg          vga_we_o,
    output reg[23:0]    vga_addr_o,

    // touch button
    input wire[5:0]     touch_btn,
            
    // ======= debug ==========
     input wire[31:0] pc,
     output reg[20:0] button_buff,
     
     output wire[`DebugBus] busdebugdata
);
    reg[31:0] uart_data_buff;
    
    
    reg             sram_ce_o;
    reg             sram_we_o;
    reg[19:0]       sram_addr_o;
    reg[`RegBus]    sram_data_o;
    reg[3:0]        sram_sel_o;
    reg[`RegBus]    sram_data_i;
    reg             sram_no;
    assign busdebugdata = {if_addr_i[7:0],mem_data_i[15:0]};
    
/*   always @ (posedge clk) begin
       if (button_buff > 0) begin
           button_buff <= button_buff - 1;
       end
   end*/
    
    
    
      
//            .probe2(uart_TxD_start_o),
//            .probe3(uart_TxD_data_o),
//            .probe4(uart_RxD_rdn_o),
//            .probe5(uart_RxD_dataready_i),
//            .probe6(uart_TxD_ready_i),
            
        //    .probe8(mem_data_o));
//            .probe9(uart_RxD_data_i));
        
    always @ (*) begin
        uart_TxD_start_o <= 1'b0;
        uart_TxD_data_o <=8'h0;
        uart_RxD_rdn_o <= 1'b1;//1 means not  
        if_stallreq_o <= `NoStop;
        mem_stallreq_o <= `NoStop;
        if_data_o <= 32'h0;
        mem_data_o <= 32'h0;
        sram_ce_o <= 1'b0;
        sram_we_o <= 1'b0;
        sram_addr_o<= 32'b0;
        sram_no <= 1'b0;
        sram_data_o<=32'b0;
        sram_sel_o <= 4'b0000;
        vga_ce_o <= 1'b0;
        vga_we_o <= 1'b0;
        vga_addr_o <= 24'h0;
        
        if (rst == `RstEnable) begin
            if_stallreq_o <= `NoStop;
            mem_stallreq_o <= `NoStop;
            if_data_o <= 32'h0;
            mem_data_o <= 32'h0;
        // end else if (flush_i == 1'b1) begin
        //     if_stallreq_o <= `NoStop;
        //     mem_stallreq_o <= `NoStop;
        //     if_data_o <= 32'h0;
        //     mem_data_o <= 32'h0;
        end else begin
            if (mem_ce_i == 1'b1) begin
                if (mem_addr_i == 32'h1FD003F8/*hbfd003f8*/) begin // UART
                    vga_ce_o <= 1'b0;
                    sram_ce_o <= 1'b0;
                    if (mem_we_i == 1'b1) begin         //如果ram不可写
                        if_stallreq_o <= `Stop;//Be careful!!!!!!!!!!!!!!!! this may be to be deleted
                        mem_stallreq_o <= `NoStop;
                        if_data_o <= 32'h0;
                        mem_data_o <= 32'h0;
                        
                        uart_TxD_start_o <= 1'b1;
                        uart_TxD_data_o <= mem_data_i[7:0];
                        uart_RxD_rdn_o <= 1'b1;
                    end else if (mem_we_i == 1'b0) begin        //ram可写
                        if_stallreq_o <= `Stop;//Be careful!!!!!!!!!!!!!!!! this may be to be deleted
                        mem_stallreq_o <= `NoStop;
                        if_data_o <= 32'h0;     //nop
                        mem_data_o <= 32'h0;
                        
                        uart_TxD_start_o <= 1'b0;
                        uart_TxD_data_o <= 8'h0;
                        uart_RxD_rdn_o <= 1'b0;
                        
                        mem_data_o <= {24'b0,uart_RxD_data_i};
                    end
                    
                end else if (mem_addr_i == 32'h1FD003FC) begin // UART status
                    if_stallreq_o <= `Stop;//Be careful!!!!!!!!!!!!!!!! this may be to be deleted
                    uart_RxD_rdn_o <= 1'b1;//not read
                    uart_TxD_start_o <= 1'b0;//not write
                    mem_data_o[31:2] <= 30'b0;
                    mem_data_o[1] <= uart_RxD_dataready_i;
                    mem_data_o[0] <= uart_TxD_ready_i;
                    vga_ce_o <= 1'b0;
                    sram_ce_o <= 1'b0;
                end else if (mem_addr_i[31:24] == 8'h1D) begin // vga mem
                    if_stallreq_o <= `Stop;
                    mem_stallreq_o <= `NoStop;
                    uart_RxD_rdn_o <= 1'b1;
                    uart_TxD_start_o <=1'b0;
                    sram_ce_o <= 1'b0;

                    vga_ce_o <= 1'b1;
                    vga_we_o <= mem_we_i;
                    vga_addr_o <= mem_addr_i[23:0];
                    vga_data_o <= mem_data_i;
                    mem_data_o <= 32'h0;
                   
                end else if (mem_addr_i[31:24] == 8'h1C) begin // touch button
                    if_stallreq_o       <= `Stop;
                    uart_RxD_rdn_o      <= 1'b1;
                    uart_TxD_start_o    <= 1'b0;         
                    sram_ce_o           <= 1'b0;
                    vga_ce_o            <= 1'b0;
                    mem_data_o <= {26'b0000_0000_0000_0000_0000_0000_00, touch_btn[5:0]};

                end else begin//Read or Write in Sram
                    if_stallreq_o <= `Stop;
                    mem_stallreq_o <= `NoStop;
                    uart_RxD_rdn_o <= 1'b1;
                    uart_TxD_start_o <= 1'b0;
                    vga_ce_o <= 1'b0;
                   
                    sram_ce_o <= 1'b1;
                    sram_we_o <= mem_we_i;
                    sram_addr_o <= mem_addr_i[21:2];
                    sram_no <= mem_addr_i[22];
                    sram_data_o <= mem_data_i;
                    sram_sel_o <= mem_sel_i;
                    mem_data_o <= sram_data_i;
                end
            
            end else if (if_ce_i == 1'b1) begin
                if_stallreq_o <= `NoStop;
                mem_stallreq_o <= `NoStop;
                uart_RxD_rdn_o <= 1'b1;
                uart_TxD_start_o<=1'b0;
                sram_ce_o <= 1'b1;
                sram_we_o <= 1'b0;
                sram_addr_o <= if_addr_i[21:2];
                sram_no <= if_addr_i[22];
                sram_data_o <= 32'h0;
                sram_sel_o <= 4'b1111;
                if_data_o <= sram_data_i;
            end else begin
                if_stallreq_o <= `NoStop;
                mem_stallreq_o <= `NoStop;
                uart_RxD_rdn_o <= 1'b1;
                uart_TxD_start_o<=1'b0;
                sram_ce_o <= 1'b0;
                sram_we_o <= 1'b0;
                sram_addr_o <= 20'b0;
                sram_data_o <= 32'h0;
                sram_sel_o <= 4'h0;
                mem_data_o <= 32'h0;
            end
        end    
    end
    
    
    always @ (*) begin
        if (sram_no == 1'b0) begin
            base_ram_ce_o      <= sram_ce_o;
            base_ram_we_o      <= sram_we_o;
            base_ram_addr_o    <= sram_addr_o;
            base_ram_data_o    <= sram_data_o;
            base_ram_sel_o     <= sram_sel_o;
            sram_data_i     <= base_ram_data_i;
        end else begin
            ext_ram_ce_o      <= sram_ce_o;
            ext_ram_we_o      <= sram_we_o;
            ext_ram_addr_o    <= sram_addr_o;
            ext_ram_data_o    <= sram_data_o;
            ext_ram_sel_o     <= sram_sel_o;
            sram_data_i     <= ext_ram_data_i;
        end
    end
    /*
    probe5(uart_TxD_ready_i),
    //            .probe6(uart_TxD_start_o),
    //            .probe7(uart_TxD_data_o),
                
    //            .probe8(uart_RxD_dataready_i),
    //            .probe9( uart_RxD_data_i),
    //            .probe10(uart_RxD_rdn_o),*/
//    assign leds[7:0] = mem_data_o[7:0] - 8'h30; 
//    assign leds[8] = uart_TxD_start_o;
//    assign leds[9] = uart_TxD_ready_i;
//    assign leds[10] = uart_RxD_dataready_i;
//    assign leds[11] = uart_RxD_rdn_o;
endmodule