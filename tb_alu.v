`timescale 1ns / 1ps

module alutest;

	// Inputs
	reg  [15:0] A;
	reg  [15:0] B;
	reg  [4:0]  Opcode;   
	
	// Outputs
	wire [15:0] Y;
	wire [4:0]  Flags;    // {Z, C, F, N, L}
	
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
		
		A = 16'h0000; 
		B = 16'h0000; 
		Opcode = uut.ADD; // Need to change based on the default Opcode
		#10; 

		// 1) ADD (signed) overflow: 0x7FFF + 1 = 0x8000  => F=1, C=0, N=1, Z=0
    	Opcode = uut.ADD;  A = 16'h7FFF; B = 16'h0001; #10;
    	$display("ADD  overflow check: A=%h B=%h -> Y=%h | Flags(Z C F N L)=%b%b%b%b%b",
             A,B,Y, Flags[4],Flags[3],Flags[2],Flags[1],Flags[0]);

		// 2) ADDU (unsigned) carry wrap: 0xFFFF + 1 = 0x0000 → C=1, Z=1, F=0
    	Opcode = uut.ADDU;  A = 16'hFFFF; B = 16'h0001; #10;
    	$display("ADDU carry wrap:     A=%h B=%h -> Y=%h | Flags(Z C F N L)=%b%b%b%b%b",
             A,B,C,Flags[4],Flags[3],Flags[2],Flags[1],Flags[0]);

	    // 3) SUB (signed) overflow: 0x8000 - 1 = 0x7FFF → F=1, borrow(C)=0
	    Opcode = uut.SUB;  A = 16'h8000; B = 16'h0001; #10;
	    $display("SUB  overflow check: A=%h B=%h -> Y=%h | Flags(Z C F N L)=%b%b%b%b%b",
             A,B,C,Flags[4],Flags[3],Flags[2],Flags[1],Flags[0]);

	    // 4) SUB borrow case: 0x0000 - 1 = 0xFFFF → borrow(C)=1, N=1
	    Opcode = uut.SUB;  A = 16'h0000; B = 16'h0001; #10;
	    $display("SUB  borrow check:   A=%h B=%h -> Y=%h | Flags(Z C F N L)=%b%b%b%b%b",
             A,B,C,Flags[4],Flags[3],Flags[2],Flags[1],Flags[0]);

	    // 5) CMP (signed): -2 vs +1 → A<B (Y is ignored by writeback, but flags tell the story)
	    Opcode = uut.CMP;  A = 16'hFFFE; B = 16'h0001; #10;
	    $display("CMP  signed:         A=%h B=%h -> Y=%h | Flags(Z C F N L)=%b%b%b%b%b",
             A,B,C,Flags[4],Flags[3],Flags[2],Flags[1],Flags[0]);

	    // 6) CMPU (unsigned): 1 < 0xFFFF → L=1
	    Opcode = uut.CMPU; A = 16'h0001; B = 16'hFFFF; #10;
	    $display("CMPU unsigned:       A=%h B=%h -> Y=%h | Flags(Z C F N L)=%b%b%b%b%b",
             A,B,C,Flags[4],Flags[3],Flags[2],Flags[1],Flags[0]);

		
		
		//RANDOM TESTS:
		
		// we can make one of these random loops for each instruction, in it we will place a
		// condition that when it fails, will trigger a $monitor variable that will print a failure message.
		for( i = 0; i< 10; i = i+ 1)
		begin
			#10
			A = $random % 65536; // bottom 16 bits
		    B = $random % 65536;
		    Opcode = uut.ADD;    // can change
		    $display("Rnd: OP=%0d A=%h B=%h -> Y=%h | Flags(Z C F N L)=%b %b %b %b %b",
		         Opcode,A,B,C,Flags[4],Flags[3],Flags[2],Flags[1],Flags[0]);
		end
		$finish(2);
		
		// Add stimulus here

	end
      
endmodule
