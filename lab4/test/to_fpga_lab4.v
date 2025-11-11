module to_fpga_lab4(
	input wire clk, reset,
	output wire [0:6] seven_seg, seven_seg2, seven_seg3, seven_seg4
);
	wire [15:0] out;

	cpu_top my_cpu (
		.clk(clk),
		.reset(reset),
		.out(out)
	);

	hex_to_7seg my_hex_to_7seg1 (
		.bcd(out[3:0]),
		.seven_seg(seven_seg)
	);

	hex_to_7seg my_hex_to_7seg2 (
		.bcd(out[7:4]),
		.seven_seg(seven_seg2)
	);

	hex_to_7seg my_hex_to_7seg3 (
		.bcd(out[11:8]),
		.seven_seg(seven_seg3)
	);

	hex_to_7seg my_hex_to_7seg4 (
		.bcd(out[15:12]),
		.seven_seg(seven_seg4)
	);
endmodule