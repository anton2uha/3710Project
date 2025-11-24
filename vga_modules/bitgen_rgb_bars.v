module bitgen_rgb_bars(
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
            //[0,213), [213,426), [426,640)
            if (hcount < 10'd213) begin
                // left: red
                vga_r = 8'hFF;
                vga_g = 8'h00;
                vga_b = 8'h00;
            end else if (hcount < 10'd426) begin
                // middle: green
                vga_r = 8'h00;
                vga_g = 8'hFF;
                vga_b = 8'h00;
            end else begin
                // right: blue
                vga_r = 8'h00;
                vga_g = 8'h00;
                vga_b = 8'hFF;
            end
        end
    end
endmodule
