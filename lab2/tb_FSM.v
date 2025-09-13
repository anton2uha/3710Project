`timescale 1ns / 1ps

module tb_FSM;

reg clk;
reg reset;
wire [15:0] out;

FSM my_FSM 
(
	.clk(clk),
	.reset(reset),
	.out(out)
);

initial begin
	// Initialize signals
	clk = 0;
	reset = 1;
	#5;
	reset = 0;
end

always #3 clk = ~clk;

initial begin	
	#200;
	$display("Result of fibonacci add: %0d", out);
	$finish;
end


endmodule