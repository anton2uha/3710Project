module vga_top(
    input  wire        sys_clk,     // 50 MHz
    output wire        VGA_HS,
    output wire        VGA_VS,
    output wire        VGA_CLK,
    output wire        VGA_BLANK_N,
    output wire        VGA_SYNC_N,
    output wire [7:0]  VGA_R,
    output wire [7:0]  VGA_G,
    output wire [7:0]  VGA_B
);
    wire bright;
    wire pix_clk;
    wire [9:0] hcount, vcount;
	 
	 // Sprite ROM signals
    wire [15:0] sprite_data;  // 16-bit RGB565 data from ROM
    wire [9:0] sprite_addr;   // Address into sprite ROM

    vga_control vc (
        .clk(sys_clk),
        .hsync(VGA_HS),
        .vsync(VGA_VS),
        .bright(bright),
        .pix_clk_out(pix_clk),
        .hcount(hcount),
        .vcount(vcount)
    );

    assign VGA_CLK     = pix_clk;
    assign VGA_BLANK_N = bright;
    assign VGA_SYNC_N  = 1'b0;

//    bitgen_red bg (
//        .bright(bright),
//        .hcount(hcount),
//        .vcount(vcount),
//        .vga_r(VGA_R),
//        .vga_g(VGA_G),
//        .vga_b(VGA_B)
//    );
	 
//	 bitgen_rgb_bars bars (
//		.bright(bright),
//      .hcount(hcount),
//      .vcount(vcount),
//      .vga_r(VGA_R),
//      .vga_g(VGA_G),
//      .vga_b(VGA_B)
//	 );
	 
// Sprite ROM - stores the glyph data
    sprite_rom #(
        .DATA_WIDTH(16),
        .ADDR_WIDTH(10)
    ) srom (
        .clk(pix_clk),
        .addr(sprite_addr),
        .data_out(sprite_data)
    );

    // Sprite renderer
    bitgen_sprite sprite_gen (
        .bright(bright),
        .hcount(hcount),
        .vcount(vcount),
        .sprite_data(sprite_data),
        .sprite_addr(sprite_addr),
        .vga_r(VGA_R),
        .vga_g(VGA_G),
        .vga_b(VGA_B)
    );
	 
endmodule
