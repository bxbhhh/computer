
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
reg[7:0] number;
SEG7_LUT segL(.oSEG1(dpy0), .iDIG(number[3:0])); //dpy0�ǵ�λ�����
SEG7_LUT segH(.oSEG1(dpy1), .iDIG(number[7:4])); //dpy1�Ǹ�λ�����

reg[15:0] led_bits;
assign leds = led_bits;

//�����ĸ�״̬
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
    if(reset_btn)begin //��λ���£�����LED�������Ϊ��ʼֵ
        number<=0;
        state<=0;
        result=0;
        led_bits <= 16'h0;
    end
    else begin //ÿ�ΰ���ʱ�Ӱ�ť���������ʾֵ��1��LEDѭ������
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
