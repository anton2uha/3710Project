`timescale 1ns / 1ps

module Regfile_ALU_Datapath(
	input clk, 
	input reset,
	input wire [3:0] opcode,    // opcode of our instruction to perform
	input wire [3:0] rdest,     // destination register
	input wire [3:0] rsrc,      // source register
	input wire [7:0] immediate, // immediate value, if needed
	input wire useImmediate,  	// whether to use immediate value or not
);

//regFile connections
reg [15:0] regEnable;
wire [15:0] rdataA;
wire [15:0] rdataB;
reg regFileWriteEnable;

//ALU connections
wire [15:0] dataA;
wire [15:0] dataB;
wire [15:0] ALUout;
reg dataAMuxEnable; 
reg immediateEnable;

twoToOneMux immMux (rdataB, {8'b0, imm}, immediateEnable, dataB);

regfile my_regs
(
	.clk(clk),
	.reset(reset),
	.wdata(regFileInput),
	.regEnable(regEnable),
	.raddrA(raddrA),
	.raddrB(raddrB),
	.rdataA(rdataA),
	.rdataB(rdataB)
);


alu my_alu 
(
	.A(dataA), 
	.B(dataB), 
	.C(ALUout), 
	.Opcode(Opcode), 
	.cin(??),
	.Flags(??)
);

endmodule
