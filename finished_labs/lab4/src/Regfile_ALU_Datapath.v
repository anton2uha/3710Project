`timescale 1ns / 1ps

module Regfile_ALU_Datapath(
	input clk, 
	input reset,
	input [3:0] opcode,     // opcode of our instruction to perform
	input [3:0] rdest,      // destination register
	input [3:0] rsrc,       // source register
	input [15:0] regEnable, // Register index to enable writing to
	input regFileWriteEnable,
	input [15:0] wdata,
	input [15:0] immediate, // immediate value, if needed
	input useImmediate,  	// whether to use immediate value or not
	output [15:0] out       // output of the ALU
);

//regFile connections
wire [15:0] rdataA;
wire [15:0] rdataB;
wire [15:0] regInput;
//reg regFileWriteEnable;

//ALU connections
wire [15:0] dataB;
reg dataAMuxEnable; 
wire [4:0] flags;
wire [15:0] aluOut;

// A or B for register input? A because A = dest
twoToOneMux immMux 
(
	.a(rdataB),
	.b(immediate),
	.sel(useImmediate),
	.y(dataB)
);

twoToOneMux regInputMux 
(
	.a(aluOut),
	.b(wdata),
	.sel(regFileWriteEnable),
	.y(regInput)
);

regfile my_regs
(
	.clk(clk),
	.reset(reset),
	.wdata(regInput),
	.regEnable(regEnable),
	.raddrA(rdest),
	.raddrB(rsrc),
	.rdataA(rdataA),
	.rdataB(rdataB)
);

alu my_alu 
(
	.A(rdataA), 
	.B(dataB), 
	.C(aluOut), 
	.Opcode(opcode), 
	.cin(flags[3]),
	.Flags(flags)
);

assign out = aluOut;

endmodule
