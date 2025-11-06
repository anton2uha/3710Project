`timescale 1ns / 1ps
module cpu_top (
	input clk,
	input reset,
	output [15:0] out // output of the ALU to show on 7 seg on fpga.
);

//enable wires (from control FSM)
wire pc_en, ir_en, reg_we, imm_en, alu_mux_ctrl;
wire [15:0] reg_en;

//instruction info (from control FSM)
wire [3:0] op, rsrc, rdest;
wire [7:0] imm8;

//memory port wires
wire [15:0] data_a, addr_a, q_a;
wire we_a;

wire [15:0] data_b, addr_b, q_b;
wire we_b;

//0 since b unused
assign data_b = 0;
assign addr_b = 0;
assign we_b = 0;

//since no data yet (simple version)
assign data_a = 0;
assign we_a = 0;

//program counter
wire [15:0] pc;

//regFile connections
wire [15:0] rdataA; //output A from regfile
wire [15:0] rdataB; //output B from regfile
wire [15:0] regFileInput;

//ALU connections
wire [15:0] dataB; //wire from imm mux to port B of ALU
wire [4:0] flags;
wire [15:0] aluOut;


//only port a used for now
true_dual_port_ram_single_clock my_ram
(
	.data_a(data_a),
	.data_b(data_b),
	.addr_a(pc),
	.addr_b(addr_b),
	.we_a(we_a),
	.we_b(we_b),
	.clk(clk),
	.q_a(q_a),
	.q_b(q_b)
);

program_counter my_pc(
	.en(pc_en), 
	.clk(clk), 
	.rst_n(reset),
	.pc(pc) //[15:0]
);

control_and_decoder my_control_decode(
	.clk(clk), //inputs
	.reset(reset),     
	.instr(q_a),        
	.flags(flags),
	
	.pc_en(pc_en), //outputs
	.ir_en(ir_en),
	.reg_we(reg_we), //CHECK: not needed? just set reg_en = 0
	.imm_en(imm_en),
	.op(op),
	.rsrc(rsrc),
	.rdest(rdest),
	.imm8(imm8),        
   .reg_en(reg_en),
	
	.alu_mux_ctrl(alu_mux_ctrl) //added	
);

// A or B for register input? A because A = dest
twoToOneMux immMux 
(
	.a(rdataB),
	.b(imm8), //CHECK: signed or zero extend?
	.sel(imm_en),
	.y(dataB)
);

twoToOneMux regFileInputMux 
(
	.a(aluOut),
	.b(q_a), //CHECK: is this same as Data_from_mem in diagram?
	.sel(alu_mux_ctrl),
	.y(regFileInput)
);

regfile my_regs
(
	.clk(clk),
	.reset(reset),
	.wdata(regFileInput),
	.regEnable(reg_en),
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
	.Opcode(op), 
	.cin(flags[3]),
	.Flags(flags)
);

assign out = aluOut;

endmodule