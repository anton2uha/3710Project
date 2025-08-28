`timescale 1ns / 1ps

module alu( A, B, C, Opcode, Flags
    );
input [3:0] A, B;
input [1:0] Opcode;
output reg [3:0] C;
output reg [4:0] Flags;

/*
parameter ADDU = 2'b00;
parameter ADD = 2'b01;
parameter SUB = 2'b10;
parameter CMP = 2'b11;
*/

parameter ADD  = 4'b0101;
parameter ADDU = 4'b0110;
parameter ADDC = 4'b0111;
//ADDCU, in list but cannot find in ISA?
parameter MUL  = 4'b1110;
parameter SUB  = 4'b1001;
parameter SUBC = 4'b1010;
parameter CMP  = 4'b1011;
parameter AND  = 4'b0001;
parameter OR   = 4'b0010;
parameter XOR  = 4'b0011;
parameter MOV  = 4'b1101;
parameter LSH  = 4'b0100;


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
		{Flags[3], C} = A + B;
		// perhaps if ({Flags[3], C} == 5'b00000) ....
		if (C == 4'b0000) Flags[4] = 1'b1; 
		else Flags[4] = 1'b0;
		Flags[2:0] = 3'b000;
		end
	ADD:
		begin
		C = A + B;
		if (C == 4'b0000) Flags[4] = 1'b1;
		else Flags[4] = 1'b0;
		if( (~A[3] & ~B[3] & C[3]) | (A[3] & B[3] & ~C[3]) ) Flags[2] = 1'b1;
		else Flags[2] = 1'b0;
		Flags[1:0] = 2'b00; Flags[3] = 1'b0;

		end
	SUB:
		begin
		C = A - B;
		if (C == 4'b0000) Flags[4] = 1'b1;
		else Flags[4] = 1'b0;
		if( (~A[3] & ~B[3] & C[3]) | (A[3] & B[3] & ~C[3]) ) Flags[2] = 1'b1;
		else Flags[2] = 1'b0;
		Flags[1:0] = 2'b00; Flags[3] = 1'b0;
		end
	CMP:
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
	default: 
		begin
			C = 4'b0000;
			Flags = 5'b00000;
		end
	endcase
end

endmodule
