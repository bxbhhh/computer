`include "defines.vh"
module sram_controller(
    // Wishbone interface
    input wire          clk,
    input wire[19:0]    addr_i,
    input wire[31:0]    data_i,
    input wire          ce_i,
    input wire          we_i,
    input wire[3:0]     sel_i,
    
    output wire[31:0]    data_o,
   
     
    // Sram interface
    inout wire[31:0]     sram_data,
    output wire[19:0]    sram_addr,
    output wire          sram_ce_n,
    output wire          sram_oe_n,
    output wire          sram_we_n,
//Byte Select
    output wire[3:0]     sram_be_n,
    // ============ debug ==============
    input wire[31:0]    reg_in,   //just for probe to debug 
    input wire[31:0]    pc,
    input wire[31:0]    inst,
    input wire[5:0]     stall


);
    assign sram_addr = addr_i;
    assign sram_ce_n = ~ce_i;
    assign sram_oe_n = ~(ce_i & (~we_i));
    assign sram_data = (ce_i & we_i)? data_i:32'bz;
    assign sram_we_n = ~((~clk) & ce_i & we_i);
    assign data_o = (ce_i & (~we_i)) ? sram_data : 32'h0;
    assign sram_be_n = (~clk) ? (~sel_i) : 4'b0000; 

    wire ila_we_n;
    assign ila_we_n = sram_we_n;
    
endmodule