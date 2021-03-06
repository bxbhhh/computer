//////////////////////////////////////////////////////////////////////
// Module:  pc_reg
// File:    pc_reg.v
// Description: 指令指针寄存器PC
// Revision: 1.0
//////////////////////////////////////////////////////////////////////

`include "defines.vh"

module pc_reg(

	input	wire clk,
	input wire	 rst,
	input wire[5:0] stall,
	output reg[`InstAddrBus]	pc,
	output reg   ce,
	
	//从译码模块传递过来的信息
    input wire                    branch_flag_i,
    input wire[`RegBus]           branch_target_address_i
	
);
//当stall[0]为NotStop时，pc+4，否则pc保持不变
	always @ (posedge clk) begin
    if (ce == `ChipDisable) begin
        pc <= 32'h00000000;
    end else if(stall[0] == `NoStop) begin
	   if(branch_flag_i == `Branch) begin   //判断此处是否转移
            pc <= branch_target_address_i;
       end else begin
            pc <= pc + 4'h4;
        end      
    end
end
	
	always @ (posedge clk) begin
		if (rst == `RstEnable) begin
			ce <= `ChipDisable;
		end else begin
			ce <= `ChipEnable;
		end
	end

endmodule