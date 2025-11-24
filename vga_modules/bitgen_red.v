module bitgen_red(
    input  wire       bright,
    input  wire [9:0] hcount,
    input  wire [9:0] vcount,
    output reg  [7:0] vga_r,
    output reg  [7:0] vga_g,
    output reg  [7:0] vga_b
);
    always @(*) begin
        if (!bright) begin
            vga_r = 8'h00;
            vga_g = 8'h00;
            vga_b = 8'h00;
        end else begin
            vga_r = 8'hFF;
            vga_g = 8'h00;
            vga_b = 8'h00;
        end
    end
endmodule
