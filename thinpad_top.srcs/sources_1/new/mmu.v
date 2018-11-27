`timescale 1ns / 1ps
`include "defines.vh"

module mmu(
    input wire[`RegBus] addr_i,
    output reg[`RegBus] addr_o
);
    always @ (*) begin
        if (addr_i >= 32'h80000000 && addr_i <= 32'h807FFFFF) begin // SRAM
            addr_o <= {9'b000000000, addr_i[22:0]};  
        end else if (addr_i >= 32'hBFD003F8 && addr_i<= 32'hBFD003FC) begin // UART
            addr_o <= {4'h1, addr_i[27:0]};
        end else if (addr_i >= 32'hBD000000 && addr_i<= 32'hBDFFFFFF) begin // vga
            addr_o <= {4'h1, addr_i[27:0]};
        end else if (addr_i == 32'hBC000000) begin // touch button
            addr_o <= {4'h1, addr_i[27:0]};
        end
    end
endmodule
