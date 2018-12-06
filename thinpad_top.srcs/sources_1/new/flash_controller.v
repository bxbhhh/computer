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
              input wire rst_i,         //Flash��λ�źţ�����Ч
              input wire vpen_i,         //Flashд�����źţ��͵�ƽʱ���ܲ�������д
              input wire cen_i,         //FlashƬѡ�źţ�����Ч
              input wire oen_i,         //Flash��ʹ���źţ�����Ч
              input wire wen_i,         //Flashдʹ���źţ�����Ч
              input wire byte_i,
        
       output wire[22:0] flash_addr,      //Flash��ַ��a0����8bitģʽ��Ч��16bitģʽ������
       inout  wire[15:0] flash_data,      //Flash����
       output wire flash_rst,         //Flash��λ�źţ�����Ч
       output wire flash_vpen,         //Flashд�����źţ��͵�ƽʱ���ܲ�������д
       output wire flash_cen,         //FlashƬѡ�źţ�����Ч
       output wire flash_oen,         //Flash��ʹ���źţ�����Ч
       output wire flash_wen,         //Flashдʹ���źţ�����Ч
       output wire flash_byte       //Flash 8bitģʽѡ�񣬵���Ч����ʹ��flash��16λģʽʱ����Ϊ1
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
