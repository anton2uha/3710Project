
module Regfile_ALU_Datapath(
	input clk, 
	input reset,
	input [15:0] instr,	// cr16a instruction to execute
	input [15:0] data    // to directly feed data into regfile,
						// will eventually be replaced with data fetched from memory?
);

// State encoding
typedef enum reg [2:0] {
	S0 = 2'b000, //reset
    S1 = 2'b001, //fetch: read instr from mem, we feed data directly for now.
    S2 = 2'b010, //decode: decode instr, update regfile
	S3 = 2'b011, //execute ALU
	S4 = 2'b100, //writeback: place output of ALU into regfile
	S5 = 2'b101  //next: updates progam counter, preps for next fetch. Not sure if we need this now?
} state_t;


module mux(
    input  wire a,      // input signal
    input  wire sel,    // enable / select signal
    output wire y       // output
);

assign y = sel ? a : 1'b0;  // propagate a only if sel is 1

endmodule



reg [15:0] regEnable;
reg [3:0] raddrA;
reg [3:0] raddrB;
wire [15:0] rdataA;
wire [15:0] rdataB;

regfile my_regs
(
	.clk(clk),
	.reset(reset),
	.wdata(??),
	.regEnable(regEnable),
	.raddrA(raddrA),
	.raddrB(raddrB),
	.rdataA(rdataA),
	.rdataB(rdataB),
);

wire [15:0] dataA;
wire [15:0] dataB;
wire [15:0] ALUout;
wire regToAluMuxEnable; //maybe need seperate enables for A and B?

mux muxA (rdataA, regToAluMuxEnable, dataA);
mux muxB (rdataB, regToAluMuxEnable, dataB);


alu my_alu 
(
	.A(dataA), 
	.B(dataB), 
	.C(ALUout), 
	.Opcode(??), 
	.cin(??),
	.Flags(??)
);



endmodule
