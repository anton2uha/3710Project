`timescale 1ns / 1ps
module tb_to_fpga;

	reg clk;
	reg reset;
	wire [6:0] HEX3;
	wire [6:0] HEX2;
	wire [6:0] HEX1;
	wire [6:0] HEX0;

	to_fpga u1
	(
		 .clk(clk),
		 .rst(reset),
		 .HEX3(HEX3),
		 .HEX2(HEX2),
		 .HEX1(HEX1),
		 .HEX0(HEX0)
	);

	initial begin
		 clk = 0;
		 reset = 0;
		 #10;
		 reset = 1;
	end

	always #5 clk = ~clk;

	initial begin	
		 #200;
		 $finish;
	end

endmodule