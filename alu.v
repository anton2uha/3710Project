`timescale 1ns / 1ps

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

parameter ADD   = 4'b0101;
parameter ADDU  = 4'b0110;
parameter ADDC  = 4'b0111;
parameter ADDCU = 4'b0100; // 1st unused OPCODE
parameter SUB   = 4'b1001;
parameter SUBC  = 4'b1010;
parameter CMP   = 4'b1011;
parameter CMPU  = 4'b????; // <------
parameter AND   = 4'b0001;
parameter OR    = 4'b0010;
parameter XOR   = 4'b0011;
parameter MOV   = 4'b1101;
parameter LSH   = 4'b0100;
parameter NOT   = 4'b????; // <------
parameter RSH   = 4'b????; // <------
parameter ALSH  = 4'b????; // <------
parameter ARSH  = 4'b????; // <------
parameter NOP   = 4'b????; // <------


/*
1. OPcode will be 4 bits, input/output 16
2. Don't need to put immediate versions of instrs here, they have same opcode as normal version.
3. Should maybe create parameters for Flags?? or reference this:
	Flags[4,3,2,1,0] = Zero(Z), Carry(C), Overflow(O), ?Low(L), ?Negative(N)
*/

always @(A, B, Opcode)
begin
	case (Opcode)
	ADDU:
		begin
		// Simply add A and B, no need to touch flags as detailed in CR16a manual
		C = A + B;
		end
	ADD:
		begin

		// Reset flags
		Flags = 5'b00000;
		// Sum A and B, and also set the carry flag if a carry happens.
		{Flags[3], C} = A + B;
		// If the sum is zero, set the Zero flag (Regardless if carry happened)
		if (C == 16'b0) Flags[4] = 1'b1;
		// Set overflow flag
		if( (~A[15] & ~B[15] & C[15]) | (A[15] & B[15] & ~C[15]) ) Flags[2] = 1'b1;

		end
	ADDC:
		begin

		// Reset flags
		Flags = 5'b00000;
		// Sum A, B, cin, and also set the carry flag if a carry happens.
		{Flags[3], C} = A + B + cin;
		// If the sum is zero, set the Zero flag (Regardless if carry happened)
		if (C == 16'b0) Flags[4] = 1'b1;
		// Set overflow flag
		if( (~A[15] & ~B[15] & C[15]) | (A[15] & B[15] & ~C[15]) ) Flags[2] = 1'b1;

		end
	SUB:
		begin

		// Reset flags
		Flags = 5'b00000;
		// Set C to 2's compl sub of A and B.
		C = A - B;
		// Set the carry flag (A<B)
		if (A < B) Flags[3] = 1'b1;
		// If C is zero, set the Zero flag
		if (C == 16'b0) Flags[4] = 1'b1;
		// If overflow happened, set the overflow flag
		if( (~A[15] & ~B[15] & C[15]) | (A[15] & B[15] & ~C[15]) ) Flags[2] = 1'b1;

		end
	SUBC:
		begin

		// Reset flags
		Flags = 5'b00000;
		// Subtract with cin
		C = A - B - cin;
		// Set the carry flag (A<B+cin)
		if (A < (B+cin)) Flags[3] = 1'b1;
		// set zero flag
		if (C == 4'b0000) Flags[4] = 1'b1;
		// set overflow flag
		if( (~A[15] & ~B[15] & C[15]) | (A[15] & B[15] & ~C[15]) ) Flags[2] = 1'b1;

		end
	CMP: // TODO
		begin
		if( $signed(A) < $signed(B) ) Flags[1:0] = 2'b11;
		else Flags[1:0] = 2'b00;
		C = 4'b0000;
		Flags[4:2] = 3'b000;
		// both positive or both negative
		/*if( A[3] == B[3] )
		begin
			if (A < B) Flags[1:0] = 2'b11;
			else Flags[1:0] = 2'b00;
		end
		else if (A[3] == 1'b0) Flags[1:0] = 2'b00;
		else Flags[1:0] = 2'b01;
		Flags[4:2] = 3'b000;
		
		// C = ?? if I don;t specify, then I'm in trouble.
		C = 4'b0000;
		*/
		end
	CMPU: // TODO
		begin
		if($unsigned(A)<$unsigned(B)) Flags[1:0] = 2'b11;
		else flags[1:0] = 2'b00;
		C=4'b0000;

		end
	AND:
	OR: 
	XOR:
	MOV:
	LSH:
	NOT:
	RSH:
	ALSH:
	ARSH:
	NOP:
	default: 
		begin
			C = 4'b0000;
			Flags = 5'b00000;
		end
	endcase
end

endmodule
