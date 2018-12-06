`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/12/06 06:00:22
// Design Name: 
// Module Name: boot_controller
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`include "defines.vh"
module boot_controller(
    input wire clk,
    input wire rst,
    input wire[15:0] flash_data_i,
    output reg flash_ce_o,
    output reg flash_oe_o,
    output reg flash_we_o,
    output reg[22:0] read_addr_o,
    output reg[22:0] write_addr_o,
    output reg[31:0] ram_data_o,
    output reg stall_req,
    output wire[`DebugBus] debugdata1,
    output wire[`DebugBus] debugdata2
    );
    reg[2:0] slow_clk;
    
    reg flag;
    reg state;
    assign debugdata1 = {write_addr_o[3:0],read_addr_o[3:0],ram_data_o[7:0],flash_data_i[7:0]};
    assign debugdata2 = {write_addr_o[7:4],read_addr_o[7:4],ram_data_o[15:8],flash_data_i[15:8]};
    initial begin
        flag <= 1'b0;
        state <= 1'b0;
        stall_req <= 1'b1;
        read_addr_o <= 32'hFFFFFFFE;
        ram_data_o <= 0;
        write_addr_o <= 0;
        slow_clk <= 0;
    end
    always @ (posedge clk) begin
        slow_clk = slow_clk+1;
    end
    
    always @ (posedge slow_clk[2]) begin
        if(flag == 1'b0) begin
            stall_req <= 1'b1;
            flag <= 1'b0;
            read_addr_o <= read_addr_o + 2;
            if(read_addr_o[1] == 1'b1) begin
                flash_ce_o <= 1'b0;
                flash_oe_o <= 1'b0;
                flash_we_o <= 1'b1;
                ram_data_o <= {flash_data_i,ram_data_o[31:16]};
                write_addr_o <= {read_addr_o[22:2],2'b0};
            end else begin
                ram_data_o <= {flash_data_i,ram_data_o[31:16]};
                write_addr_o <= {read_addr_o[22:2],2'b0};
            end
        end
        if(ram_data_o == 32'hffffffff) begin
                stall_req <= 1'b0;
                flag <= 1'b1;
                flash_ce_o <= 1'b1;
                flash_oe_o <= 1'b1;
                flash_we_o <= 1'b1;
        end
        if(ram_data_o[22] == 1'b1) begin
            stall_req <= 1'b0;
            flag <= 1'b1;
            flash_ce_o <= 1'b1;
            flash_oe_o <= 1'b1;
            flash_we_o <= 1'b1;
        end
    end
endmodule
