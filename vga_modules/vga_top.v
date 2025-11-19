`timescale 1ns / 1ps

module vga_top(
    input  wire sys_clk,
    output wire hsync,
    output wire vsync,
    output wire [2:0] rgb
);

    wire bright;
	 wire pix_clk_out;
    wire [9:0] hcount;
    wire [9:0] vcount;
	 
vga_control vc (
    .clk(sys_clk),
    .hsync(hsync),
    .vsync(vsync),
    .bright(bright),
    .pix_clk_out(pix_clk_out),
    .hcount(hcount),
    .vcount(vcount)
);

bitgen bg (
    .clk(pix_clk_out),
    .bright(bright),
    .hcount(hcount),
    .vcount(vcount),
    .rgb(rgb)
);

endmodule
