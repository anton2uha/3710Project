`timescale 1ns / 1ps

module tb_regfile;

	reg clk, reset;
	reg [15:0] wdata, regEnable;
	reg [3:0] raddrA, raddrB;
	wire [15:0] rdataA, rdataB;

	regfile DUT (
		 .clk(clk),
		 .reset(reset),
		 .wdata(wdata),
		 .regEnable(regEnable),
		 .raddrA(raddrA),
		 .raddrB(raddrB),
		 .rdataA(rdataA),
		 .rdataB(rdataB)
	);

	initial begin
		// Initialize signals
		clk = 0;
		reset = 1;
		wdata = 16'h0000;
		regEnable = 16'h0000;
		raddrA = 4'h0;
		raddrB = 4'h0;
	end

	// Clock generation
	always #5 clk = ~clk;

	initial begin
		// Monitor changes. Displays all inputs and outputs
		$monitor("Time: %0t | clk: %b | reset: %b | wdata: %h | regEnable: %b | raddrA: %h | raddrB: %h | rdataA: %h | rdataB: %h", 
					$time, clk, reset, wdata, regEnable, raddrA, raddrB, rdataA, rdataB);

		// Release reset
		reset = 0;
		#10;

		$display("writing ABCD to register 3");
		wdata = 16'hABCD;
		regEnable = 16'b0000_0000_0000_1000; 
		#10;

		$display("writing 1234 to register 5");
		wdata = 16'h1234;
		regEnable = 16'b0000_0000_0010_0000;
		#10;

		$display("Reading registers 3 and 5");
		regEnable = 16'b0000_0000_0000_0000; // Disable writing to ensure no reg is written to
		// Read from register 3
		raddrA = 4'h3; 
		// Read from register 5
		raddrB = 4'h5; 
		#10;

		$finish;
	end
endmodule