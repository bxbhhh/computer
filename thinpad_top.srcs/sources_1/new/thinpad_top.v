//////////////////////////////////////////////////////////////////////
// Module:  thinpad
// File:    thinpad.v
// Author:  BaiReny
// E-mail:  bry6789@163.com
// Description: thinpad引脚
// Revision: 1.0
//////////////////////////////////////////////////////////////////////
`default_nettype none

module thinpad_top(
    input wire clk_50M,           //50MHz 时钟输入
    input wire clk_11M0592,       //11.0592MHz 时钟输入

    input wire clock_btn,         //BTN5手动时钟按钮开关，带消抖电路，按下时为1
    input wire reset_btn,         //BTN6手动复位按钮开关，带消抖电路，按下时为1

    input  wire[3:0]  touch_btn,  //BTN1~BTN4，按钮开关，按下时为1
    input  wire[31:0] dip_sw,     //32位拨码开关，拨到"ON"时为1
    output wire[15:0] leds,       //16位LED，输出时1点亮
    output wire[7:0]  dpy0,       //数码管低位信号，包括小数点，输出1点亮
    output wire[7:0]  dpy1,       //数码管高位信号，包括小数点，输出1点亮

    //CPLD串口控制器信号
    output wire uart_rdn,         //读串口信号，低有效
    output wire uart_wrn,         //写串口信号，低有效
    input wire uart_dataready,    //串口数据准备好
    input wire uart_tbre,         //发送数据标志
    input wire uart_tsre,         //数据发送完毕标志

    //BaseRAM信号
    inout wire[31:0] base_ram_data,  //BaseRAM数据，低8位与CPLD串口控制器共享
    output wire[19:0] base_ram_addr, //BaseRAM地址
    output wire[3:0] base_ram_be_n,  //BaseRAM字节使能，低有效。如果不使用字节使能，请保持为0
    output wire base_ram_ce_n,       //BaseRAM片选，低有效
    output wire base_ram_oe_n,       //BaseRAM读使能，低有效
    output wire base_ram_we_n,       //BaseRAM写使能，低有效

    //ExtRAM信号
    inout wire[31:0] ext_ram_data,  //ExtRAM数据
    output wire[19:0] ext_ram_addr, //ExtRAM地址
    output wire[3:0] ext_ram_be_n,  //ExtRAM字节使能，低有效。如果不使用字节使能，请保持为0
    output wire ext_ram_ce_n,       //ExtRAM片选，低有效
    output wire ext_ram_oe_n,       //ExtRAM读使能，低有效
    output wire ext_ram_we_n,       //ExtRAM写使能，低有效

    //直连串口信号
    output wire txd,  //直连串口发送端
    input  wire rxd,  //直连串口接收端

    //Flash存储器信号，参考 JS28F640 芯片手册
    output wire [22:0]flash_a,      //Flash地址，a0仅在8bit模式有效，16bit模式无意义
    inout  wire [15:0]flash_d,      //Flash数据
    output wire flash_rp_n,         //Flash复位信号，低有效
    output wire flash_vpen,         //Flash写保护信号，低电平时不能擦除、烧写
    output wire flash_ce_n,         //Flash片选信号，低有效
    output wire flash_oe_n,         //Flash读使能信号，低有效
    output wire flash_we_n,         //Flash写使能信号，低有效
    output wire flash_byte_n,       //Flash 8bit模式选择，低有效。在使用flash的16位模式时请设为1

    //USB 控制器信号，参考 SL811 芯片手册
    output wire sl811_a0,
    //inout  wire[7:0] sl811_d,     //USB数据线与网络控制器的dm9k_sd[7:0]共享
    output wire sl811_wr_n,
    output wire sl811_rd_n,
    output wire sl811_cs_n,
    output wire sl811_rst_n,
    output wire sl811_dack_n,
    input  wire sl811_intrq,
    input  wire sl811_drq_n,

    //网络控制器信号，参考 DM9000A 芯片手册
    output wire dm9k_cmd,
    inout  wire[15:0] dm9k_sd,
    output wire dm9k_iow_n,
    output wire dm9k_ior_n,
    output wire dm9k_cs_n,
    output wire dm9k_pwrst_n,
    input  wire dm9k_int,

    //图像输出信号
    output wire[2:0] video_red,    //红色像素，3位
    output wire[2:0] video_green,  //绿色像素，3位
    output wire[1:0] video_blue,   //蓝色像素，2位
    output wire video_hsync,       //行同步（水平同步）信号
    output wire video_vsync,       //场同步（垂直同步）信号
    output wire video_clk,         //像素时钟输出
    output wire video_de           //行数据有效信号，用于区分消隐区
);


/* =========== Demo code begin =========== */


// 数码管连接关系示意图，dpy1同理
// p=dpy0[0] // ---a---
// c=dpy0[1] // |     |
// d=dpy0[2] // f     b
// e=dpy0[3] // |     |
// b=dpy0[4] // ---g---
// a=dpy0[5] // |     |
// f=dpy0[6] // e     c
// g=dpy0[7] // |     |
//           // ---d---  p



// 7段数码管译码器演示，将number用16进制显示在数码管上面
wire[`DebugBus] debugdata;
SEG7_LUT segL(.oSEG1(dpy0), .iDIG(debugdata[19:16])); //dpy0是低位数码管
SEG7_LUT segH(.oSEG1(dpy1), .iDIG(debugdata[23:20])); //dpy1是高位数码管
assign leds[15:0] = debugdata[15:0];
  //连接指令存储器
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
  assign uart_rdn = 1'b1;
  assign uart_wrn = 1'b1;
//  assign base_ram_ce_n = ce;
//  assign base_ram_oe_n = oe;
//  assign base_ram_we_n = we;
//  assign base_ram_be_n = 4'b0;
//  assign base_ram_addr = 20'b0;
//  assign base_ram_data = 32'bz;
  
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


wire locked, clk_10M, clk_20M,clk_30M,clk_40M,clk_45M,clk_42M,clk_43M;
pll_example clock_gen 
 (
  // Clock out ports
  .clk_out1(clk_10M), // 时钟输出1，频率在IP配置界面中设置
  .clk_out3(clk_30M),
  .clk_out4(clk_40M),
  .clk_out4_2(clk_42M),
  .clk_put4_3(clk_43M),
  .clk_out4_5(clk_45M),
  // Status and control signals
  .reset(reset_btn), // PLL复位输入
  .locked(locked), // 锁定输出，"1"表示时钟稳定，可作为后级电路复位
 // Clock in ports
  .clk_in1(clk_50M) // 外部时钟输入
 );
    
    wire[5:0] int;
    
    
    
  //例化处理器cpu
  cpu cpu0(
    .clk_uart(clk_43M),
    .clk(clk_43M),
    .rst(reset_btn),  
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
   
   .flash_addr(flash_a),      //Flash地址，a0仅在8bit模式有效，16bit模式无意义
   .flash_data(flash_d),      //Flash数据
   .flash_rst(flash_rp_n),         //Flash复位信号，低有效
   .flash_vpen(flash_vpen),         //Flash写保护信号，低电平时不能擦除、烧写
   .flash_cen(flash_ce_n),         //Flash片选信号，低有效
   .flash_oen(flash_oe_n),         //Flash读使能信号，低有效
   .flash_wen(flash_we_n),         //Flash写使能信号，低有效
   .flash_byte(flash_byte_n),        //Flash 8bit模式选择，低有效。在使用flash的16位模式时请设为1
   
   .TxD(txd),
   .RxD(rxd),
  //debug
    .debug(dip_sw[5:0]),
    .debugdata(debugdata)  
  );


endmodule
