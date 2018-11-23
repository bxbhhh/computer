
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
reg[7:0] number;
SEG7_LUT segL(.oSEG1(dpy0), .iDIG(number[3:0])); //dpy0是低位数码管
SEG7_LUT segH(.oSEG1(dpy1), .iDIG(number[7:4])); //dpy1是高位数码管

reg[15:0] led_bits;
assign leds = led_bits;

//定义四个状态
reg[1:0] state;
parameter S0 = 2'b00;
parameter S1 = 2'b01;
parameter S2 = 2'b10;
parameter S3 = 2'b11;

parameter Add = 4'b0001;
parameter Sub = 4'b0010;
parameter And = 4'b0010;
parameter Or  = 4'b0011;
parameter Xor = 4'b0100;
parameter Not = 4'b0101;
parameter Sll = 4'b0111;
parameter Srl = 4'b1000;
parameter Sra = 4'b1001;
parameter Rol = 4'b1010;

reg[31:0] a;
reg[31:0] b;
reg[3:0] op;
reg[31:0] result;

reg cf = 1'b0; //Carry Flag 
reg zf = 1'b0; //Zero Flag 
reg sf = 1'b0; //Signed Flag 
reg vf = 1'b0; //Overflow Flag

always@(posedge clock_btn or posedge reset_btn) begin
    if(reset_btn)begin //复位按下，设置LED和数码管为初始值
        number<=0;
        state<=0;
        result=0;
        led_bits <= 16'h0;
    end
    else begin //每次按下时钟按钮，数码管显示值加1，LED循环左移
        // led_bits <= {led_bits[14:0],led_bits[15]};
        case(state)
            S0:begin
                a=dip_sw;
                number=0;
                led_bits=16'h0;
                result=0;
                op = 0;
                cf = 1'b0;
                zf = 1'b0;
                sf = 1'b0;
                vf = 1'b0;
            end
            S1:begin
                b=dip_sw;
            end
            S2:begin
                op= dip_sw[3:0];
            end
            S3:begin
                case(op)
                    Add:begin
                        result=a+b;
                        if(result==0)begin
                            zf = 1'b1;
                        end
                        if(result < a)begin
                            cf = 1'b1;
                        end
                        if(result[31]==1'b1)begin
                            sf = 1'b1;
                        end
                        if((result[31] != a[31]) &&(a[31] ==b[31]))begin
                            vf = 1'b1;
                        end
                    end
                    Sub:begin
                        result=a-b;
                        if(result==0)begin
                            zf = 1'b1;
                        end
                        if(result < a)begin
                            cf = 1'b1;
                        end
                        if(result[31]==1'b1)begin
                            sf = 1'b1;
                        end
                        if((result[31] != a[31]) &&(a[31] ==b[31]))begin
                            vf = 1'b1;
                        end
                    end
                    And:begin
                        result=a&b;
                        if(result==0)begin
                            zf = 1'b1;
                        end
                        if(result[31]==1'b1)begin
                            sf = 1'b1;
                        end
                    end
                    Or:begin
                        result=a|b;
                        if(result==0)begin
                            zf = 1'b1;
                         end
                        if(result[31]==1'b1)begin
                            sf = 1'b1;
                        end
                    end
                    Xor:begin
                        result=a^b;
                        if(result==0)begin
                            zf = 1'b1;
                         end
                        if(result[31]==1'b1)begin
                            sf = 1'b1;
                        end
                    end
                    Not:begin
                        result=!a;
                        if(result==0)begin
                            zf = 1'b1;
                         end
                        if(result[31]==1'b1)begin
                            sf = 1'b1;
                        end
                    end
                    Sll:begin
                        result=a<<b;
                        if(result==0)begin
                            zf = 1'b1;
                        end
                    end
                    Srl:begin
                        result=a>>b;
                        if(result==0)begin
                            zf = 1'b1;
                         end
                        if(result[31]==1'b1)begin
                            sf = 1'b1;
                        end
                    end
                    Sra:begin
                        result=a>>>b;
                        if(result==0)begin
                            zf = 1'b1;
                         end
                        if(result[31]==1'b1)begin
                            sf = 1'b1;
                        end
                    end
                    Rol:begin
                        result=(a<<b)|(a>>(32-b));
                        if(result==0)begin
                            zf = 1'b1;
                         end
                        if(result[31]==1'b1)begin
                            sf = 1'b1;
                        end
                    end
                endcase
            end
            default:
                result=0;
        endcase
        state = state+1;
        number <= result;
        led_bits[15] <= cf;
        led_bits[14] <= zf;
        led_bits[13] <= sf;
        led_bits[12] <= vf;
        led_bits[11:0]  <= 0;
    end
end

/* =========== Demo code end =========== */

endmodule
