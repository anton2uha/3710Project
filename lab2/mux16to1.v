
module mux16to1(
  input  [15:0] d0,  input [15:0] d1,
  input  [15:0] d2,  input [15:0] d3,
  input  [15:0] d4,  input [15:0] d5,
  input  [15:0] d6,  input [15:0] d7,
  input  [15:0] d8,  input [15:0] d9,
  input  [15:0] d10, input [15:0] d11,
  input  [15:0] d12, input [15:0] d13,
  input  [15:0] d14, input [15:0] d15,
  input  [3:0]  sel,
  output reg [15:0] y
);

  always @* begin
    case (sel)
      4'h0: y = d0;   4'h1: y = d1;   4'h2: y = d2;   4'h3: y = d3;
      4'h4: y = d4;   4'h5: y = d5;   4'h6: y = d6;   4'h7: y = d7;
      4'h8: y = d8;   4'h9: y = d9;   4'hA: y = d10;  4'hB: y = d11;
      4'hC: y = d12;  4'hD: y = d13;  4'hE: y = d14;  4'hF: y = d15;
    endcase
  end
endmodule
