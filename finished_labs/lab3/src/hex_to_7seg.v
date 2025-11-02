module hex_to_7seg(bcd,seven_seg);

input wire [3:0] bcd;
output reg [0:6] seven_seg;

always @*
 begin
  case (bcd)
   4'b0000 : begin seven_seg = ~7'b1111110; end // 0 - 0000001
   4'b0001 : begin seven_seg = ~7'b0110000; end // 1 - 1001111
   4'b0010 : begin seven_seg = ~7'b1101101; end // 2 - 0010010
   4'b0011 : begin seven_seg = ~7'b1111001; end // 3 - 0000110
   4'b0100 : begin seven_seg = ~7'b0110011; end // 4 - 1001100
   4'b0101 : begin seven_seg = ~7'b1011011; end // 5 - 0100100
   4'b0110 : begin seven_seg = ~7'b1011111; end // 6 - 0100000
   4'b0111 : begin seven_seg = ~7'b1110000; end // 7 - 0001111
   4'b1000 : begin seven_seg = ~7'b1111111; end // 8 - 0000000
   4'b1001 : begin seven_seg = ~7'b1110011; end // 9 - 0001100
	4'b1010 : begin seven_seg = ~7'b1110111; end // a - 0001000
	4'b1011 : begin seven_seg = ~7'b0011111; end // b - 1100000
	4'b1100 : begin seven_seg = ~7'b1001110; end // c - 0110001
	4'b1101 : begin seven_seg = ~7'b0111101; end // d - 1000010
	4'b1110 : begin seven_seg = ~7'b1001111; end // e - 0110000
	4'b1111 : begin seven_seg = ~7'b1000111; end // f - 0111000
   default : begin seven_seg = ~7'b0000000; end 
  endcase
 end
endmodule