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
		parameter NUMLOOPS = 10;
		
		
		Opcode = 4'b0101; //ADD
		for(i = 0; i < NUMLOOPS; i = i + 1)
		begin
			A = $random % 65536; //bottom 16 bits, 2^16
			B = $random % 65536;
			#10
			if ($signed(A) + $signed(B) != $signed(C)) begin 
				$display("RANDOM TEST FAILED! A: %0d, B: %0d, C: %0d, Flags[4:0]: %b, time:%0d", A, B, C, Flags[4:0], $time); 
			end
		end
		
		
		Opcode = 4'b0110; //ADDU
		for(i = 0; i < NUMLOOPS; i = i + 1)
		begin
			A = $random % 65536;
			B = $random % 65536;
			#10
			if (A + B != C) begin 
				$display("RANDOM TEST FAILED! A: %0d, B: %0d, C: %0d, Flags[4:0]: %b, time:%0d", A, B, C, Flags[4:0], $time); 
			end
		end
		
		
		Opcode = 4'b0110; //ADDC
		for(i = 0; i < NUMLOOPS; i = i + 1)
		begin
			A = $random % 65536;
			B = $random % 65536;
			Flags[3] = $random % 2; //0 or 1
			#10
			if ($signed(A) + $signed(B) + $signed({1'b0, Flags[3]}) != $signed(C)) begin 
				$display("RANDOM TEST FAILED! A: %0d, B: %0d, C: %0d, Flags[4:0]: %b, time:%0d", A, B, C, Flags[4:0], $time); 
			end
		end
		
		
		Opcode = 4'b1110; //MUL
		for(i = 0; i < NUMLOOPS; i = i + 1)
		begin
			A = $random % 65536;
			B = $random % 65536;
			#10
			if ($signed(A) * $signed(B) != $signed(C)) begin 
				$display("RANDOM TEST FAILED! A: %0d, B: %0d, C: %0d, Flags[1:0]: %b, time:%0d", A, B, C, Flags[4:0], $time); 
			end
		end
		
		
		Opcode = 4'b0101; //SUB
		for(i = 0; i < NUMLOOPS; i = i + 1)
		begin
			A = $random % 65536; 
			B = $random % 65536;
			#10
			if ($signed(A) - $signed(B) != $signed(C)) begin 
				$display("RANDOM TEST FAILED! A: %0d, B: %0d, C: %0d, Flags[4:0]: %b, time:%0d", A, B, C, Flags[4:0], $time); 
			end
		end
		
		
		Opcode = 4'b1011; //CMP
		for(i = 0; i < NUMLOOPS; i = i + 1)
		begin
			A = $random % 65536; 
			B = $random % 65536;
			#10
			
			if ($signed(A) == $signed(B)) begin
				if(Flags[4] != 1) begin
					$display("RANDOM TEST FAILED! A: %0d, B: %0d, C: %0d, Flags[4:0]: %b, time:%0d", A, B, C, Flags[4:0], $time);
				end
			end
			else if ($signed(A) > $signed(B)) begin
				if(Flags[0] != 1) begin
					$display("RANDOM TEST FAILED! A: %0d, B: %0d, C: %0d, Flags[4:0]: %b, time:%0d", A, B, C, Flags[4:0], $time);
				end
			end
			else begin
				if(Flags[1] != 1) begin
					$display("RANDOM TEST FAILED! A: %0d, B: %0d, C: %0d, Flags[4:0]: %b, time:%0d", A, B, C, Flags[4:0], $time);
				end
			end
			
		end
		
		
		Opcode = 4'b0101; //AND
		for(i = 0; i < NUMLOOPS; i = i + 1)
		begin
			A = $random % 65536;
			B = $random % 65536;
			#10
			if ((A & B) != C) begin 
				$display("RANDOM TEST FAILED! A: %0d, B: %0d, C: %0d, Flags[4:0]: %b, time:%0d", A, B, C, Flags[4:0], $time); 
			end
		end
		
		
		Opcode = 4'b0010; //OR
		for(i = 0; i < NUMLOOPS; i = i + 1)
		begin
			A = $random % 65536;
			B = $random % 65536;
			#10
			if ((A | B) != C) begin 
				$display("RANDOM TEST FAILED! A: %0d, B: %0d, C: %0d, Flags[4:0]: %b, time:%0d", A, B, C, Flags[4:0], $time); 
			end
		end
		
		
		Opcode = 4'b0011; //XOR
		for(i = 0; i < NUMLOOPS; i = i + 1)
		begin
			A = $random % 65536;
			B = $random % 65536;
			#10
			if ((A ^ B) != C) begin 
				$display("RANDOM TEST FAILED! A: %0d, B: %0d, C: %0d, Flags[4:0]: %b, time:%0d", A, B, C, Flags[4:0], $time); 
			end
		end

	end
      
endmodule
