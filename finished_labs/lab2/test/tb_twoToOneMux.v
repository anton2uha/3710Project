module tb_twoToOneMux;

	reg [15:0] a;
	reg [15:0] b;
	reg sel;
	wire [15:0] out;

	twoToOneMux uut (
	.a(a),
	.b(b),
	.sel(sel),
	.y(out)
	);

	initial begin
		// Initialize inputs
		a = 16'hAAAA; // Example value for input a
		b = 16'h5555; // Example value for input b
		sel = 0;      // Start with sel = 0

		// Monitor changes
		$monitor("Time: %0t | sel: %b | a: %h | b: %h | out: %h", $time, sel, a, b, out);

		// sel = 0, expect out = a
		$display("selecting a");
		sel = 0;
		#10;

		// sel = 1, expect out = b
		$display("selecting b");
		sel = 1;
		#10;

		// Change inputs and test again
		// Expect out = a
		$display("selecting a");
		a = 16'hFFFF;
		b = 16'h0000;
		sel = 0; 
		#10;

		// Expect out = b
		$display("selecting b");
		sel = 1; 
		#10;

		$finish;
	end
endmodule