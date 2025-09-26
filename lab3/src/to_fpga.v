module to_fpga(
  input clk, rst,
  output wire [0:6]  HEX3,  // left most
  output wire [0:6]  HEX2,
  output wire [0:6]  HEX1,
  output wire [0:6]  HEX0   // right most
);

wire [15:0] out;

FSM my_FSM 
(
	.clk(clk),
	.reset(rst),
	.out(out)
);

hex_to_7seg u3(
  .bcd(out[15:12]),
  .seven_seg(HEX3)
);

hex_to_7seg u2(
  .bcd(out[11:8]),
  .seven_seg(HEX2)
);

hex_to_7seg u1(
  .bcd(out[7:4]),
  .seven_seg(HEX1)
);

hex_to_7seg u0(
  .bcd(out[3:0]),
  .seven_seg(HEX0)
);

endmodule