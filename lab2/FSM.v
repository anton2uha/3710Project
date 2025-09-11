module FSM (input wire [15:0] instr, input clk, input reset);



Regfile_ALU_Datapath my_dataPath
(
	.clk(clk),
	.reset(reset),
	.opcode(),
	.rdest(),
	.rsrc(),
	.immediate(),
	.useImmediate()
);

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


parameter S0 = 3'b001;
parameter S1 = 3'b010;
parameter S2 = 3'b011;
parameter S3 = 3'b100;
parameter S4 = 3'b101;

reg [2:0] state;
//this loop takes care of state
always @(posedge clk or posedge reset) begin
    if (reset)
        state <= FETCH;       // start in FETCH after reset
    else begin
        case (state)
            S0: state <= S1;
            S1: state <= S2;
            S2: state <= S3;
            S3: state <= S4;
            default:     state <= S0;   // safety
        endcase
    end
end


//this loop executes logic for current state.
always @(*) begin
	case (state)
		S0: begin
			
		
		end
	
	
	
	
	endcase


end




endmodule