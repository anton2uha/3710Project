`timescale 1ns / 1ps

// A is destination register, B is source register
module alu( A, B, C, Opcode, cin, Flags);
input [15:0] A, B;
input [3:0] Opcode;
input cin;
output reg [15:0] C;
output reg [4:0] Flags;

/*
parameter ADDU = 2'b00;
parameter ADD = 2'b01;
parameter SUB = 2'b10;
parameter CMP = 2'b11;

/*
ADD, ADDI, ADDU, ADDUI, ADDC, ADDCU, ADDCUI, ADDCI, SUB, SUBI, CMP, CMPI, CMPU/I, AND,
OR, XOR, NOT, LSH, LSHI, RSH, RSHI, ALSH, ARSH, NOP/WAIT
*/

parameter NOP   = 4'b0000;
parameter AND   = 4'b0001;
parameter OR    = 4'b0010;
parameter XOR   = 4'b0011;
// 0100 reserved for jcond
parameter ADD   = 4'b0101;
parameter ADDU  = 4'b0110;
parameter ADDC  = 4'b0111;
parameter NOT   = 4'b1000;
parameter SUB   = 4'b1001;
parameter SUBC  = 4'b1010;
parameter CMP   = 4'b1011;
// 1100 reserved for bcond
parameter MOV   = 4'b1101;
parameter ASHU  = 4'b1110;
parameter LSH   = 4'b1111;


/*
1. OPcode will be 4 bits, input/output 16
2. Don't need to put immediate versions of instrs here, they have same opcode as normal version.
3. Should maybe create parameters for Flags?? or reference this:
	Flags[4,3,2,1,0] = Zero(Z), Carry(C), Overflow(O), ?Low(L), ?Negative(N)
*/

always @(A, B, cin, Opcode)
begin
	// Initialize/Reset outputs to remove latch inferences
	C = 16'b0;
	Flags = 5'b0;

	case (Opcode)
	ADDU: // does not set flags
		begin
		// Simply add A and B, no need to touch flags as detailed in CR16a manual
		C = A + B;
		end
	ADD: // sets carry and overflow flags
		begin

		// Reset flags
		Flags = 5'b00000;
		// Sum A and B, and also set the carry flag if a carry happens.
		{Flags[3], C} = A + B;
		// Set overflow flag
		if( (~A[15] & ~B[15] & C[15]) | (A[15] & B[15] & ~C[15]) ) Flags[2] = 1'b1;

		end
	ADDC: // sets carry and overflow flags
		begin

		// Reset flags
		Flags = 5'b00000;
		// Sum A, B, cin, and also set the carry flag if a carry happens.
		{Flags[3], C} = A + B + cin;
		// Set overflow flag
		if( (~A[15] & ~B[15] & C[15]) | (A[15] & B[15] & ~C[15]) ) Flags[2] = 1'b1;

		end
	SUB: // sets carry and overflow flags
		begin

		// Reset flags
		Flags = 5'b00000;
		// Set C to 2's compl sub of A and B.
		C = A - B;
		// Set the carry flag (A<B)
		if (A < B) Flags[3] = 1'b1;
		// If overflow happened, set the overflow flag
		if( (~A[15] & ~B[15] & C[15]) | (A[15] & B[15] & ~C[15]) ) Flags[2] = 1'b1;
		end
	SUBC: // sets carry and overflow flags
		begin

		// Reset flags
		Flags = 5'b00000;
		// Subtract with cin
		C = A - B - cin;
		// Set the carry flag (A<B+cin)
		if (A < (B+cin)) Flags[3] = 1'b1;
		// set overflow flag
		if( (~A[15] & ~B[15] & C[15]) | (A[15] & B[15] & ~C[15]) ) Flags[2] = 1'b1;

		end
	CMP: // sets zero, low, negative flags
		begin

		// Reset flags
		Flags = 5'b00000;
		// If A==B is zero, set the Zero flag
		if (A == B) Flags[4] = 1'b1;
		// Set the negative flag if A > B (signed)
		if ($signed(A) > $signed(B)) Flags[0] = 1'b1;
		// Set the low flag if A > B (unsigned)
		if ($unsigned(A) > $unsigned(B)) Flags[1] = 1'b1;

		end
	AND: // does not set flags
		begin

		C = A & B;

		end
	OR: 
		begin

		C = A | B;

		end
	XOR:
		begin

		C = A ^ B;

		end
	//MOV: Without a reg file I am not sure how to implement this
	MOV: 
		begin

		C = B;

		end
	LSH: // does not set flags. Also supports negative shifts (right shifts) per CR16a manual
		begin
        if ($signed(B) >= 0)
            C = A << B;
        else // If B is negative, do a logical right shift instead
            C = A >> (-$signed(B));
        end	
	NOT:
		begin

		C = ~A;

		end
	ASHU: // Arithmetic Shift. Does not set flags

		begin
		if ($signed(B) >= 0)
			C = A << B;
		else // If B is negative, do a arithmetic right shift instead (preserves sign bit)
			C = ($signed(A) >>> (-$signed(B)));

		end
	NOP: begin end // No operation, do nothing

	// q: what's the difference between ashu and lsh? both seem to do logical left shifts and right shifts based on sign of B. 

	default: // undefined behavior
		begin

			C = 4'b0000;
			Flags = 5'b00000;

		end
	endcase
end

endmodule
