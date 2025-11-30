module bitgen(
    input  wire       bright,
    input  wire [9:0] hcount,
    input  wire [9:0] vcount,
    output reg  [2:0] rgb
);
    always @(*) begin
        if (!bright) begin
            rgb = 3'b000;   // black during blanking
        end else begin
            rgb = 3'b100;   // solid red
        end
    end
endmodule
