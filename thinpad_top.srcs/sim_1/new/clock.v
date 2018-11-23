`timescale 1ps / 1ps

module clock(
);

    reg sys_rst_n;
    reg sys_clk ;
    reg clk_50M;         //50MHz 时钟输入
    reg clk_11M0592;       //11.0592MHz 时钟输入
    
    initial 
    begin
        sys_rst_n = 1;
        sys_clk = 0;
        clk_50M = 1;
        clk_11M0592 = 1;
        #200 sys_rst_n = 1'b0;
    end

    always #20000 clk_50M <= ~clk_50M;
    always #90000 clk_11M0592 <= ~clk_11M0592;
    always #20 sys_clk <= ~sys_clk;

    thinpad_top test(.clock_btn(sys_clk),.reset_btn(sys_rst_n),.clk_50M(clk_50M),.clk_11M0592(clk_11M0592));

endmodule
