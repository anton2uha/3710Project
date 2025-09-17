module twoToOneMux (
    input [15:0] a, b,
    input sel,
    output reg [15:0] out
);

always @(*) begin
    case (sel)
        1'b0: out = a;
        1'b1: out = b;
    endcase
end

endmodule