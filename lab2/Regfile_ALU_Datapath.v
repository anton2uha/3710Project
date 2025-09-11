`timescale 1ns / 1ps

module Regfile_ALU_Datapath(
	input clk, 
	input reset,
	input [3:0] opcode,     // opcode of our instruction to perform
	input [3:0] rdest,      // destination register
	input [3:0] rsrc,       // source register
	input [15:0] immediate, // immediate value, if needed
	input useImmediate,  	 // whether to use immediate value or not
	output [15:0] out
);

//regFile connections
reg [15:0] regEnable;
wire [15:0] rdataA;
wire [15:0] rdataB;
reg regFileWriteEnable;

//ALU connections
wire [15:0] dataA;
wire [15:0] dataB;
reg dataAMuxEnable; 
reg immediateEnable;
reg [4:0] flags;

// A or B for register input? A because A = dest
twoToOneMux immMux 
(
	.a(rdataA),
	.b(imm),
	.sel(immediateEnable)
);

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
	.C(out), 
	.Opcode(opcode), 
	.cin(flags[3]),
	.Flags(flags)
);

endmodule
