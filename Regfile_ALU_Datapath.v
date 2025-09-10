
module twoToOneMux (
    input  wire [15:0] a,
    input  wire [15:0] b,
    input  wire        sel,   // 1-bit select
    output wire [15:0] y
);
    assign y = sel ? b : a;   // if sel=1 → b, else → a
endmodule


// Lets split this out
// I don't feel the bus should be in charge of control logic. 
// Therefore, instead of taking a 16 bit intruction input, we should divide that out into control signals
// and values for registers. 

// The control logic will be very useful for testing and potentially future labs. 
module Regfile_ALU_Datapath(
	input clk, 
	input reset,
	input wire [15:0] instr,	// cr16a instruction to execute
	input wire [15:0] inData    // to directly feed data into regfile,
								// will eventually be replaced with data fetched from memory?
);


//regFile connections
reg [15:0] regEnable;
reg [3:0] raddrA = instr[11:8]; //rdest
reg [3:0] raddrB;  //rsrc
wire [15:0] regFileInput;
wire [15:0] rdataA;
wire [15:0] rdataB;
reg regFileWriteEnable;

//ALU connections
wire [15:0] dataA;
wire [15:0] dataB;
wire [15:0] ALUout;
reg dataAMuxEnable; 
reg immediateEnable;


//extract info from instr. Below works for most but not all instrs, like shifts, will come back.
reg [3:0] Opcode;
reg [7:0] imm;
reg isImmediate;
always @(*) begin
    if (instr[15:12] == 4'b0000) begin
        Opcode = instr[7:4];
		  raddrB = instr[3:0];
		  imm = 8'b0;
		  isImmediate = 0;
    end else begin
        Opcode = instr[15:12];
		  raddrB = 4'b0;
		  imm = instr[7:0];
		  isImmediate = 1;
	 end
end

twoToOneMux dataAMux (rdataA, rdataA, dataAMuxEnable, dataA);
twoToOneMux immMux (rdataB, {8'b0, imm}, immediateEnable, dataB);
twoToOneMux regFileMux (inData, ALUout, regFileWriteEnable, regFileInput);

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


//FSM
parameter FETCH = 3'b001;  //fetch: read instr from mem, we feed data directly for now.
parameter DECODE = 3'b010; //decode: decode instr, update regfile
parameter EXECALU = 3'b011;  //execute ALU
parameter WRITEBACK = 3'b100; //writeback: place output of ALU into regfile

reg [2:0] state;
//this loop takes care of state: FETCH -> DECODE -> EXECUTE -> WRITEBACK -> FETCH
always @(posedge clk or posedge reset) begin
    if (reset)
        state <= FETCH;       // start in FETCH after reset
    else begin
        case (state)
            FETCH:     state <= DECODE;
            DECODE:    state <= EXECALU;
            EXECALU:   state <= WRITEBACK;
            WRITEBACK: state <= FETCH;   // loop back
            default:     state <= FETCH;   // safety
        endcase
    end
end

//this loop executes logic for current state.
always @(*) begin
	case (state)
		FETCH: begin
			regFileWriteEnable = 1'b0; //inData
			dataAMuxEnable = 1'b0;
			immediateEnable = 1'b0;
		end
			
		DECODE: begin
			regFileWriteEnable = 1'b0;
			dataAMuxEnable = 1'b0;
			immediateEnable = 1'b0;
		end
			
		EXECALU: begin
			regFileWriteEnable = 1'b0;
			dataAMuxEnable = 1'b1;
			if(isImmediate == 1) 
				immediateEnable = 1'b1;
			else
				immediateEnable = 1'b0;			
			end
			
		WRITEBACK: begin
			regFileWriteEnable = 1'b1; //ALUout
			dataAMuxEnable = 1'b0;
			immediateEnable = 1'b0;
		end
			
		default: begin
			regFileWriteEnable = 1'b0;
			dataAMuxEnable = 1'b0;
			immediateEnable = 1'b0;
		end
		
	endcase
end


endmodule
