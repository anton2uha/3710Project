
module Regfile_ALU_Datapath(
	input clk, 
	input reset,
	input [15:0] instr,	// cr16a instruction to execute
	input [15:0] inData    // to directly feed data into regfile,
								// will eventually be replaced with data fetched from memory?
);


//mux modules
module mux(
    input [15:0] wire a,    
    input wire sel,
    output [15:0] wire y       
);

assign y = sel ? a : 16'b0;  // propagate a only if sel is 1

endmodule

module twoToOneMux (
	input [15:0] wire a,
	input [15:0] wire b,
	input [1:0] wire sel,
	output [15:0] wire out
);

always @(*) begin
	case (sel) 
		2'b01: out = a;
		2'b10: out = b;
		default: out = 16'b0;
	endcase
end

endmodule


//regFile connections
reg [15:0] regEnable;
reg [3:0] raddrA = instr[11:8]; //rdest
reg [3:0] raddrB;  //rsrc
wire [15:0] regFileInput;
wire [15:0] rdataA;
wire [15:0] rdataB;
reg [1:0] regFileWriteEnable;

//ALU connections
wire [15:0] dataA;
wire [15:0] dataB;
wire [15:0] ALUout;
reg dataAMuxEnable; //maybe need seperate enables for A and B?
reg [1:0] immediateEnable;


//extract info from instr. Below works for most but not all instrs, like shifts, will come back.
reg [3:0] Opcode;
reg [7:0] imm;
always @(*) begin
    if (instr[15:12] == 4'b0000)
        Opcode = instr[7:4];
		  raddrB = instr[3:0];
		  imm = 8'b0;
		  immediateEnable = 2'b00;
    else
        Opcode = instr[15:12];
		  raddrB = 4'b0;
		  imm = instr[7:0];
		  immediateEnable = 2'b01;
end




mux muxA (rdataA, regToAluMuxEnable, dataA);
twoToOneMux immMux (rdataB, imm, immediateEnable, dataB);
twoToOneMux muxRegFile (inData, ALUout, regFileWriteEnable, regFileInput);

regfile my_regs
(
	.clk(clk),
	.reset(reset),
	.wdata(regFileInput),
	.regEnable(regEnable),
	.raddrA(raddrA),
	.raddrB(raddrB),
	.rdataA(rdataA),
	.rdataB(rdataB),
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


//FSM
parameter RESET = 2'b000;  //reset
parameter FETCH = 2'b001;  //fetch: read instr from mem, we feed data directly for now.
parameter DECODE = 2'b010; //decode: decode instr, update regfile
parameter EXECALU = 2'b011;  //execute ALU
parameter WRITEBACK = 2'b100; //writeback: place output of ALU into regfile

reg [2:0] state;
//this loop takes care of state: FETCH -> DECODE -> EXECUTE -> WRITEBACK -> FETCH
always @(posedge clk or posedge reset) begin
    if (reset)
        state <= FETCH;       // start in FETCH after reset
    else begin
        case (state)
            FETCH:     state <= DECODE;
            DECODE:    state <= EXECUTE;
            EXECUTE:   state <= WRITEBACK;
            WRITEBACK: state <= FETCH;   // loop back
            default:     state <= FETCH;   // safety
        endcase
    end
end

//this loop executes logic for current state.
always @(posedge clk, posedge reset) begin
	if (reset) begin
		state <= RESET;
		regFileInputEnable <= 2'b00;
	end else begin
		case (state)
			FETCH: begin
				regFileWriteEnable = 2'b01; //dataIn
				dataAMuxEnable = 1'b0;
				immediateEnable = 1'b00;
			end
			
			DECODE: begin
				regFileWriteEnable = 2'b11;
				dataAMuxEnable = 1'b0;
				immediateEnable = 1'b11;
			end
			
			EXECALU: begin
				
			end
			
			WRITEBACK: begin
				regFileWriteEnable = 2'b10; //ALUout
				dataAMuxEnable = 1'b0;
				immediateEnable = 1'b00;
			end
			
			default: begin
				regFileWriteEnable = 2'b00;
				dataAMuxEnable = 1'b0;
				immediateEnable = 1'b00;
			end
		
		endcase
	end
	
end


endmodule
