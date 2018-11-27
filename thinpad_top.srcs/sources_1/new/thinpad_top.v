//////////////////////////////////////////////////////////////////////
// Module:  thinpad
// File:    thinpad.v
// Author:  BaiReny
// E-mail:  bry6789@163.com
// Description: thinpad����
// Revision: 1.0
//////////////////////////////////////////////////////////////////////
`default_nettype none

module thinpad_top(
    input wire clk_50M,           //50MHz ʱ������
    input wire clk_11M0592,       //11.0592MHz ʱ������

    input wire clock_btn,         //BTN5�ֶ�ʱ�Ӱ�ť���أ���������·������ʱΪ1
    input wire reset_btn,         //BTN6�ֶ���λ��ť���أ���������·������ʱΪ1

    input  wire[3:0]  touch_btn,  //BTN1~BTN4����ť���أ�����ʱΪ1
    input  wire[31:0] dip_sw,     //32λ���뿪�أ�����"ON"ʱΪ1
    output wire[15:0] leds,       //16λLED�����ʱ1����
    output wire[7:0]  dpy0,       //����ܵ�λ�źţ�����С���㣬���1����
    output wire[7:0]  dpy1,       //����ܸ�λ�źţ�����С���㣬���1����

    //CPLD���ڿ������ź�
    output wire uart_rdn,         //�������źţ�����Ч
    output wire uart_wrn,         //д�����źţ�����Ч
    input wire uart_dataready,    //��������׼����
    input wire uart_tbre,         //�������ݱ�־
    input wire uart_tsre,         //���ݷ�����ϱ�־

    //BaseRAM�ź�
    inout wire[31:0] base_ram_data,  //BaseRAM���ݣ���8λ��CPLD���ڿ���������
    output wire[19:0] base_ram_addr, //BaseRAM��ַ
    output wire[3:0] base_ram_be_n,  //BaseRAM�ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣��Ϊ0
    output wire base_ram_ce_n,       //BaseRAMƬѡ������Ч
    output wire base_ram_oe_n,       //BaseRAM��ʹ�ܣ�����Ч
    output wire base_ram_we_n,       //BaseRAMдʹ�ܣ�����Ч

    //ExtRAM�ź�
    inout wire[31:0] ext_ram_data,  //ExtRAM����
    output wire[19:0] ext_ram_addr, //ExtRAM��ַ
    output wire[3:0] ext_ram_be_n,  //ExtRAM�ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣��Ϊ0
    output wire ext_ram_ce_n,       //ExtRAMƬѡ������Ч
    output wire ext_ram_oe_n,       //ExtRAM��ʹ�ܣ�����Ч
    output wire ext_ram_we_n,       //ExtRAMдʹ�ܣ�����Ч

    //ֱ�������ź�
    output wire txd,  //ֱ�����ڷ��Ͷ�
    input  wire rxd,  //ֱ�����ڽ��ն�

    //Flash�洢���źţ��ο� JS28F640 оƬ�ֲ�
    output wire [22:0]flash_a,      //Flash��ַ��a0����8bitģʽ��Ч��16bitģʽ������
    inout  wire [15:0]flash_d,      //Flash����
    output wire flash_rp_n,         //Flash��λ�źţ�����Ч
    output wire flash_vpen,         //Flashд�����źţ��͵�ƽʱ���ܲ�������д
    output wire flash_ce_n,         //FlashƬѡ�źţ�����Ч
    output wire flash_oe_n,         //Flash��ʹ���źţ�����Ч
    output wire flash_we_n,         //Flashдʹ���źţ�����Ч
    output wire flash_byte_n,       //Flash 8bitģʽѡ�񣬵���Ч����ʹ��flash��16λģʽʱ����Ϊ1

    //USB �������źţ��ο� SL811 оƬ�ֲ�
    output wire sl811_a0,
    //inout  wire[7:0] sl811_d,     //USB�������������������dm9k_sd[7:0]����
    output wire sl811_wr_n,
    output wire sl811_rd_n,
    output wire sl811_cs_n,
    output wire sl811_rst_n,
    output wire sl811_dack_n,
    input  wire sl811_intrq,
    input  wire sl811_drq_n,

    //����������źţ��ο� DM9000A оƬ�ֲ�
    output wire dm9k_cmd,
    inout  wire[15:0] dm9k_sd,
    output wire dm9k_iow_n,
    output wire dm9k_ior_n,
    output wire dm9k_cs_n,
    output wire dm9k_pwrst_n,
    input  wire dm9k_int,

    //ͼ������ź�
    output wire[2:0] video_red,    //��ɫ���أ�3λ
    output wire[2:0] video_green,  //��ɫ���أ�3λ
    output wire[1:0] video_blue,   //��ɫ���أ�2λ
    output wire video_hsync,       //��ͬ����ˮƽͬ�����ź�
    output wire video_vsync,       //��ͬ������ֱͬ�����ź�
    output wire video_clk,         //����ʱ�����
    output wire video_de           //��������Ч�źţ���������������
);


/* =========== Demo code begin =========== */


// ��������ӹ�ϵʾ��ͼ��dpy1ͬ��
// p=dpy0[0] // ---a---
// c=dpy0[1] // |     |
// d=dpy0[2] // f     b
// e=dpy0[3] // |     |
// b=dpy0[4] // ---g---
// a=dpy0[5] // |     |
// f=dpy0[6] // e     c
// g=dpy0[7] // |     |
//           // ---d---  p



// 7���������������ʾ����number��16������ʾ�����������
wire[`DebugBus] debugdata;
SEG7_LUT segL(.oSEG1(dpy0), .iDIG(debugdata[19:16])); //dpy0�ǵ�λ�����
SEG7_LUT segH(.oSEG1(dpy1), .iDIG(debugdata[23:20])); //dpy1�Ǹ�λ�����
assign leds[15:0] = debugdata[15:0];
  //����ָ��洢��
  wire[`InstAddrBus] inst_addr;
  wire[`InstBus] inst;
  wire rom_ce;
  wire mem_we_i;
  wire[`RegBus] mem_addr_i;
  wire[`RegBus] mem_data_i;
  wire[`RegBus] mem_data_o;
  wire[3:0] mem_sel_i;  
  wire mem_ce_i;    
  
  reg ce;
  reg oe;
  reg we;
//  assign base_ram_ce_n = ce;
//  assign base_ram_oe_n = oe;
//  assign base_ram_we_n = we;
//  assign base_ram_be_n = 4'b0;
//  assign base_ram_addr = 20'b0;
//  assign base_ram_data = 32'bz;
  
  assign uart_rdn = 1'b1;
  assign uart_wrn = 1'b1;
//     always @(*) begin
//         case(dip_sw[5:0])
//             6'b101000 : begin
//                         ce <= 1'b1;
//                         oe <= 1'b1;
//                         we <= 1'b1;
//             end
//             6'b001000 : begin
//                ce <= 1'b0;
//                oe <= 1'b0;
//                we <= 1'b1;
//             end
//             6'b001001: begin
//                 debugdata <= {base_ram_addr,base_ram_ce_n,base_ram_oe_n,base_ram_we_n,1'b0};
//             end
//             6'b001010: begin
//                 debugdata <= {base_ram_be_n,base_ram_data[19:0]};

//             end
//         endcase
//     end
     
    
  //����������cpu
  cpu cpu0(
  .clk(clock_btn),
  .rst(reset_btn),
//  .rom_addr_o(inst_addr),
//  .rom_data_i(inst),
//  .rom_ce_o(rom_ce),
  
//  .ram_we_o(mem_we_i),
//  .ram_addr_o(mem_addr_i),
//  .ram_sel_o(mem_sel_i),
//  .ram_data_o(mem_data_i),
//  .ram_data_i(mem_data_o),
//  .ram_ce_o(mem_ce_i),
  
   .base_ram_data(base_ram_data),
   .base_ram_addr(base_ram_addr),
   .base_ram_ce_n(base_ram_ce_n),
   .base_ram_oe_n(base_ram_oe_n),
   .base_ram_we_n(base_ram_we_n),
   .base_ram_be_n(base_ram_be_n),
   
   .ext_ram_data(ext_ram_data),
   .ext_ram_addr(ext_ram_addr),
   .ext_ram_ce_n(ext_ram_ce_n),
   .ext_ram_oe_n(ext_ram_oe_n),
   .ext_ram_we_n(ext_ram_we_n),
   .ext_ram_be_n(ext_ram_be_n),
  //debug
    .debug(dip_sw[5:0]),
    .debugdata(debugdata)  
  );
  
//  //����ָ��洢��
//  	inst_rom inst_rom0(
//      .addr(inst_addr),
//      .inst(inst),
//      .ce(rom_ce)    
//  );
////�������ݴ洢��
//  data_ram data_ram0(
//     .clk(clock_btn),
//     .we(mem_we_i),
//     .addr(mem_addr_i),
//     .sel(mem_sel_i),
//     .data_i(mem_data_i),
//     .data_o(mem_data_o),
//     .ce(mem_ce_i)        
//  );


endmodule
