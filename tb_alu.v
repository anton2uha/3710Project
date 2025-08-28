`timescale 1ns / 1ps

module alutest;

	// Inputs
	reg [3:0] A;
	reg [3:0] B;
	reg [1:0] Opcode;

	// Outputs
	wire [3:0] C;
	wire [4:0] Flags;

	integer i;
	// Instantiate the Unit Under Test (UUT)
	alu uut (
		.A(A), 
		.B(B), 
		.C(C), 
		.Opcode(Opcode), 
		.Flags(Flags)
	);

	initial begin
			$monitor("A: %0d, B: %0d, C: %0d, Flags[1:0]:%b, time:%0d", A, B, C, Flags[1:0], $time );

//Instead of the $display stmt in the loop, you could use just this
//monitor statement which is executed everytime there is an event on any
//signal in the argument list.

		//SPECIFIC AND CORNER CASE TESTS:
		
		// Initialize Inputs
		//A = 0;
		//A = 0;
		//B = 0;
		//Opcode = 2'b11;

		// Wait 100 ns for global reset to finish
/*****
		// One vector-by-vector case simulation
		//#10;
	        //Opcode = 2'b11;
		//A = 4'b0010; B = 4'b0011;
		//#10
		//A = 4'b1111; B = 4'b 1110;
		//$display("A: %b, B: %b, C:%b, Flags[1:0]: %b, time:%d", A, B, C, Flags[1:0], $time);
****/
		A = 16'h0000; B = 16'h0000; Opcode = 31; #10; // NOP

		// 1) ADD (signed) overflow: 0x7FFF + 1 = 0x8000  => F=1, C=0, N=1, Z=0
    	Opcode = 1;  A = 16'h7FFF; B = 16'h0001; #10;
    	$display("ADD  overflow check: A=%h B=%h -> Y=%h | Flags(Z C F N L)=%b%b%b%b%b",
             A,B,Y, Flags[4],Flags[3],Flags[2],Flags[1],Flags[0]);

		// 2) ADDU (unsigned) carry wrap: 0xFFFF + 1 = 0x0000 => C=1, Z=1, F=0
    	Opcode = 0;  A = 16'hFFFF; B = 16'h0001; #10;
    	$display("ADDU carry wrap:     A=%h B=%h -> Y=%h | Flags(Z C F N L)=%b%b%b%b%b",
             A,B,Y, Flags[4],Flags[3],Flags[2],Flags[1],Flags[0]);

    	// 3) SUB (signed) overflow: 0x8000 - 1 = 0x7FFF => F=1, borrow(C)=0
    	Opcode = 3;  A = 16'h8000; B = 16'h0001; #10;
    	$display("SUB  overflow check: A=%h B=%h -> Y=%h | Flags(Z C F N L)=%b%b%b%b%b",
             A,B,Y, Flags[4],Flags[3],Flags[2],Flags[1],Flags[0]);

    	// 4) SUB borrow case: 0x0000 - 1 = 0xFFFF => borrow(C)=1, N=1
    	Opcode = 3;  A = 16'h0000; B = 16'h0001; #10;
    	$display("SUB  borrow check:   A=%h B=%h -> Y=%h | Flags(Z C F N L)=%b%b%b%b%b",
             A,B,Y, Flags[4],Flags[3],Flags[2],Flags[1],Flags[0]);

    	// 5) CMP (signed): -2 vs +1 => A < B 
    	Opcode = 4;  A = 16'hFFFE; B = 16'h0001; #10;
    	$display("CMP  signed:         A=%h B=%h -> Y=%h | Flags(Z C F N L)=%b%b%b%b%b",
             A,B,Y, Flags[4],Flags[3],Flags[2],Flags[1],Flags[0]);

    	// 6) CMPU (unsigned): 1 < 0xFFFF => L=1
    	Opcode = 5;  A = 16'h0001; B = 16'hFFFF; #10;
    	$display("CMPU unsigned:       A=%h B=%h -> Y=%h | Flags(Z C F N L)=%b%b%b%b%b",
             A,B,Y, Flags[4],Flags[3],Flags[2],Flags[1],Flags[0]);

		
		
		//RANDOM TESTS:
		
		// we can make one of these random loops for each instruction, in it we will place a
		// condition that when it fails, will trigger a $monitor variable that will print a failure message.
		for( i = 0; i< 10; i = i+ 1)
		begin
			#10
			A = $random % 65536; //bottom 16 bits, 2^16
			B = $random % 65536;
			$display("A: %0d, B: %0d, C: %0d, Flags[1:0]: %b, time:%0d", A, B, C, Flags[1:0], $time );
		end
		$finish(2);
		
		// Add stimulus here

	end
      
endmodule
