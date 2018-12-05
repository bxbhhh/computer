//////////////////////////////////////////////////////////////////////
// Module:  pc_reg
// File:    pc_reg.v
// Description: ָ��ָ��Ĵ���PC
// Revision: 1.0
//////////////////////////////////////////////////////////////////////

`include "defines.vh"

module pc_reg(

	input	wire clk,
	input wire	 rst,
	input wire[5:0] stall,
	output reg[`InstAddrBus]	pc,
	output reg   ce,
	//�ж��쳣
	input wire flush,
    input wire[`RegBus]   new_pc, //����������
	
	//������ģ�鴫�ݹ�������Ϣ
    input wire                    branch_flag_i,
    input wire[`RegBus]           branch_target_address_i
	
);

//��stall[0]ΪNotStopʱ��pc+4������pc���ֲ���
	always @ (posedge clk) begin
    if (ce == `ChipDisable) begin
        pc <= 32'h80000000;
    end else begin 
        if (flush == 1'b1) begin
            pc <= new_pc;// exception happens , get exception hanler in new_pc from ctrl module;
        end else if(stall[0] == `NoStop) begin
	       if(branch_flag_i == `Branch) begin   //�жϴ˴��Ƿ�ת��
                pc <= branch_target_address_i;
            end else begin
                pc <= pc + 4'h4;
            end      
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