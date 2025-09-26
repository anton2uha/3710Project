module twoToOneMux (
    input  wire [15:0] a,
    input  wire [15:0] b,
    input  wire        sel,   // 1-bit select
    output wire [15:0] y
);
    assign y = sel ? b : a;   // if sel=1 → b, else → a
endmodule