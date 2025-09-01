`timescale 1ns / 1ps

module alutest;

	// Inputs
	reg [15:0] A;
	reg [15:0] B;
	reg [3:0] Opcode;

	// Outputs
	wire [15:0] C;
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
		//$monitor("A: %0d, B: %0d, C: %0d, Flags[1:0]:%b, time:%0d", A, B, C, Flags[1:0], $time );



		//SPECIFIC AND CORNER CASE TESTS:
		

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

		
		
		
		//RANDOM TESTS:
		parameter NUMLOOPS = 10;
		
		
		Opcode = 4'b0101; //ADD
		for(i = 0; i < NUMLOOPS; i = i + 1)
		begin
			A = $random % 65536; //bottom 16 bits, 2^16
			B = $random % 65536;
			#10
			if ($signed(A) + $signed(B) != $signed(C)) begin 
				$display("RANDOM TEST FAILED! Opcode: %0b, A: %0d, B: %0d, C: %0d, Flags[4:0]: %b, time:%0d", Opcode, A, B, C, Flags[4:0], $time); 
			end
		end
		
		
		Opcode = 4'b0110; //ADDU
		for(i = 0; i < NUMLOOPS; i = i + 1)
		begin
			A = $random % 65536;
			B = $random % 65536;
			#10
			if (A + B != C) begin 
				$display("RANDOM TEST FAILED! Opcode: %0b, A: %0d, B: %0d, C: %0d, Flags[4:0]: %b, time:%0d", Opcode, A, B, C, Flags[4:0], $time); 
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
				$display("RANDOM TEST FAILED! Opcode: %0b, A: %0d, B: %0d, C: %0d, Flags[4:0]: %b, time:%0d", Opcode, A, B, C, Flags[4:0], $time); 
			end
		end
		
		/* possibly just use ADDC
		Opcode = 4'b????; //ADDCU
		for(i = 0; i < NUMLOOPS; i = i + 1)
		begin
			A = $random % 65536;
			B = $random % 65536;
			Flags[3] = $random % 2;
			#10
			if (A + B + Flags[3] != C) begin 
				$display("RANDOM TEST FAILED! Opcode: %0b, A: %0d, B: %0d, C: %0d, Flags[4:0]: %b, time:%0d", Opcode, A, B, C, Flags[4:0], $time); 
			end
		end
		*/
		
		Opcode = 4'b1110; //MUL
		for(i = 0; i < NUMLOOPS; i = i + 1)
		begin
			A = $random % 65536;
			B = $random % 65536;
			#10
			if ($signed(A) * $signed(B) != $signed(C)) begin 
				$display("RANDOM TEST FAILED! Opcode: %0b, A: %0d, B: %0d, C: %0d, Flags[4:0]: %b, time:%0d", Opcode, A, B, C, Flags[4:0], $time); 
			end
		end
		
		
		Opcode = 4'b0101; //SUB
		for(i = 0; i < NUMLOOPS; i = i + 1)
		begin
			A = $random % 65536; 
			B = $random % 65536;
			#10
			if ($signed(A) - $signed(B) != $signed(C)) begin 
				$display("RANDOM TEST FAILED! Opcode: %0b, A: %0d, B: %0d, C: %0d, Flags[4:0]: %b, time:%0d", Opcode, A, B, C, Flags[4:0], $time); 
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
					$display("RANDOM TEST FAILED! Opcode: %0b, A: %0d, B: %0d, C: %0d, Flags[4:0]: %b, time:%0d", Opcode, A, B, C, Flags[4:0], $time);
				end
			end
			if ($signed(A) > $signed(B)) begin
				if(Flags[0] != 1) begin
					$display("RANDOM TEST FAILED! Opcode: %0b, A: %0d, B: %0d, C: %0d, Flags[4:0]: %b, time:%0d", Opcode, A, B, C, Flags[4:0], $time);
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
				$display("RANDOM TEST FAILED! Opcode: %0b, A: %0d, B: %0d, C: %0d, Flags[4:0]: %b, time:%0d", Opcode, A, B, C, Flags[4:0], $time); 
			end
		end
		
		
		Opcode = 4'b0010; //OR
		for(i = 0; i < NUMLOOPS; i = i + 1)
		begin
			A = $random % 65536;
			B = $random % 65536;
			#10
			if ((A | B) != C) begin 
				$display("RANDOM TEST FAILED! Opcode: %0b, A: %0d, B: %0d, C: %0d, Flags[4:0]: %b, time:%0d", Opcode, A, B, C, Flags[4:0], $time); 
			end
		end
		
		
		Opcode = 4'b0011; //XOR
		for(i = 0; i < NUMLOOPS; i = i + 1)
		begin
			A = $random % 65536;
			B = $random % 65536;
			#10
			if ((A ^ B) != C) begin 
				$display("RANDOM TEST FAILED! Opcode: %0b, A: %0d, B: %0d, C: %0d, Flags[4:0]: %b, time:%0d", Opcode, A, B, C, Flags[4:0], $time); 
			end
		end
		
		//NOT implemeted with XOR
		Opcode = 4'b0011; //XOR
		for(i = 0; i < NUMLOOPS; i = i + 1)
		begin
			A = $random % 65536;
			B = {16{1'b1}};
			#10
			if (!A != C) begin 
				$display("RANDOM TEST FAILED! Opcode: %0b, A: %0d, B: %0d, C: %0d, Flags[4:0]: %b, time:%0d", Opcode, A, B, C, Flags[4:0], $time); 
			end
		end
		
		
		//L(ogical)SH implements both L(eft)SH and R(ight)SH, depending on sign of src.
		Opcode = 4'b0100; //LSH
		for(i = 0; i < NUMLOOPS; i = i + 1)
		begin
			A = $random % 65536; //src (interpreted as signed)
			B = $random % 65536; //dest (unsigned)
			#10
			
			reg [15:0] abs_A = (A < 0) ? -A : A; //absolute value of A
			
			if($signed(A) >= 0) begin //left
				if (C != B << abs_A) begin
					$display("RANDOM TEST FAILED! Opcode: %0b, A: %0d, B: %0d, C: %0d, Flags[4:0]: %b, time:%0d", Opcode, A, B, C, Flags[4:0], $time);
				end
			end
			
			else begin //right
				if (C != B >> abs_A) begin
					$display("RANDOM TEST FAILED! Opcode: %0b, A: %0d, B: %0d, C: %0d, Flags[4:0]: %b, time:%0d", Opcode, A, B, C, Flags[4:0], $time);
				end
			end
		end
		
		//ASHU implements both ALSH and ARSH, direction determined by sign of src
		Opcode = 4'b0110; //LSH
		for(i = 0; i < NUMLOOPS; i = i + 1)
		begin
			A = $random % 65536; //src (interpreted as signed)
			B = $random % 65536; //dest (also signed)
			#10
			
			reg [15:0] abs_A = (A < 0) ? -A : A; //absolute value of A
			
			if($signed(A) >= 0) begin //left
				if (C != B << abs_A) begin //arithmetic left is equivalent to logical left
					$display("RANDOM TEST FAILED! Opcode: %0b, A: %0d, B: %0d, C: %0d, Flags[4:0]: %b, time:%0d", Opcode, A, B, C, Flags[4:0], $time);
				end
			end
			
			else begin //right
				if (C != B >>> abs_A) begin //arithmetic right: >>>
					$display("RANDOM TEST FAILED! Opcode: %0b, A: %0d, B: %0d, C: %0d, Flags[4:0]: %b, time:%0d", Opcode, A, B, C, Flags[4:0], $time);
				end
			end

		end
		
		//TODO?: NOP/WAIT

	end
      
endmodule
