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
		A = 0;
		A = 0;
		B = 0;
		Opcode = 2'b11;

		// Wait 100 ns for global reset to finish
/*****
		// One vector-by-vector case simulation
		#10;
	        Opcode = 2'b11;
		A = 4'b0010; B = 4'b0011;
		#10
		A = 4'b1111; B = 4'b 1110;
		//$display("A: %b, B: %b, C:%b, Flags[1:0]: %b, time:%d", A, B, C, Flags[1:0], $time);
****/
		
		
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
