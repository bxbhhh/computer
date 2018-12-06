`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/12/06 11:00:08
// Design Name: 
// Module Name: flash_controller
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


module flash_controller(
        input wire[22:0] addr_i,
        input wire[31:0] data_i,
              input wire rst_i,         //Flash复位信号，低有效
              input wire vpen_i,         //Flash写保护信号，低电平时不能擦除、烧写
              input wire cen_i,         //Flash片选信号，低有效
              input wire oen_i,         //Flash读使能信号，低有效
              input wire wen_i,         //Flash写使能信号，低有效
              input wire byte_i,
        
       output wire[22:0] flash_addr,      //Flash地址，a0仅在8bit模式有效，16bit模式无意义
       inout  wire[15:0] flash_data,      //Flash数据
       output wire flash_rst,         //Flash复位信号，低有效
       output wire flash_vpen,         //Flash写保护信号，低电平时不能擦除、烧写
       output wire flash_cen,         //Flash片选信号，低有效
       output wire flash_oen,         //Flash读使能信号，低有效
       output wire flash_wen,         //Flash写使能信号，低有效
       output wire flash_byte       //Flash 8bit模式选择，低有效。在使用flash的16位模式时请设为1
    );
    assign flash_data = (~flash_cen & ~flash_wen)? data_i:32'bz;
    assign flash_addr =  addr_i;
    assign flash_rst = rst_i;
    assign vpen_i = vpen_i;
    assign flash_cen = cen_i;
    assign flash_oen = oen_i;
    assign flash_wen = wen_i;
    assign flash_byte = byte_i;
endmodule
