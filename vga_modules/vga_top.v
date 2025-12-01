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
	 wire [15:0] sprite_data;
    wire [11:0] sprite_addr;

	 localparam MAN_BASE_ADDR    = 13'd0;
	 localparam CACTUS_BASE_ADDR = 13'd4096;

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

	wire [12:0] man_addr;
	wire [12:0] cactus_addr;
	wire [15:0] man_data;
	wire [15:0] cactus_data;
	
	wire [7:0] man_r, man_g, man_b;
	wire [7:0] cactus_r, cactus_g, cactus_b;
	wire       man_opaque;
	wire       cactus_opaque;

	sprite_rom_dp #(
		 .DATA_WIDTH(16),
		 .ADDR_WIDTH(13)
	) srom (
		 .clk(pix_clk),
		 .addr_a(man_addr),     // port A for man
		 .addr_b(cactus_addr),  // port B for cactus
		 .q_a(man_data),
		 .q_b(cactus_data)
	);

	// man sprite
	bitgen_animated_sprite #(
		 .BASE_ADDR(MAN_BASE_ADDR)
	) man (
		 .pix_clk(pix_clk),
		 .bright(bright),
		 .hcount(hcount),
		 .vcount(vcount),
		 .sprite_data(man_data),
		 .sprite_addr(man_addr),
		 .vga_r(man_r),
		 .vga_g(man_g),
		 .vga_b(man_b),
		 .pixel_opaque(man_opaque)
	);

	// cactus sprite
	bitgen_cactus_sprite #(
		 .BASE_ADDR(CACTUS_BASE_ADDR)
	) cactus (
		 .pix_clk(pix_clk),
		 .bright(bright),
		 .hcount(hcount),
		 .vcount(vcount),
		 .sprite_data(cactus_data),
		 .sprite_addr(cactus_addr),
		 .vga_r(cactus_r),
		 .vga_g(cactus_g),
		 .vga_b(cactus_b),
		 .pixel_opaque(cactus_opaque)
	);
	
    reg [7:0] vga_r_reg;
    reg [7:0] vga_g_reg;
    reg [7:0] vga_b_reg;
	
	assign VGA_R = vga_r_reg;
    assign VGA_G = vga_g_reg;
    assign VGA_B = vga_b_reg;

	// layering (man in front of cactus, background behind)
	always @(*) begin
		 if (!bright) begin
			  vga_r_reg = 8'h00;
			  vga_g_reg = 8'h00;
			  vga_b_reg = 8'h00;
		 end else if (man_opaque) begin
			  // man on top
			  vga_r_reg = man_r;
			  vga_g_reg = man_g;
			  vga_b_reg = man_b;
		 end else if (cactus_opaque) begin
			  // cactus behind man
			  vga_r_reg = cactus_r;
			  vga_g_reg = cactus_g;
			  vga_b_reg = cactus_b;
		 end else begin
			  // background if no sprite draws here
			  vga_r_reg = 8'h88;
			  vga_g_reg = 8'hCC;
			  vga_b_reg = 8'h88;
		 end
	end


	 
endmodule
