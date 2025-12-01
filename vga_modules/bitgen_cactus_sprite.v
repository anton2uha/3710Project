module bitgen_cactus_sprite #(
    parameter SPRITE_WIDTH   = 32,
    parameter SPRITE_HEIGHT  = 32,
    parameter SCALE          = 3,
    parameter BASE_ADDR      = 13'd4096    // cactus start
)(
    input  wire        pix_clk,
    input  wire        bright,
    input  wire [9:0]  hcount,
    input  wire [9:0]  vcount,
    input  wire [15:0] sprite_data,
    output reg  [12:0] sprite_addr,
    output reg  [7:0]  vga_r,
    output reg  [7:0]  vga_g,
    output reg  [7:0]  vga_b,
	 output reg pixel_opaque
);
    localparam SCALED_WIDTH  = SPRITE_WIDTH * SCALE;
    localparam SCALED_HEIGHT = SPRITE_HEIGHT * SCALE;
	 
	 parameter SCREEN_WIDTH = 640;
    parameter SCREEN_HEIGHT = 480;
	 
	 parameter BG_R = 8'h88;
    parameter BG_G = 8'hcc;
    parameter BG_B = 8'h88;
	 

    // e.g., fixed cactus position for now
    localparam CACTUS_X = 10'd400;
    localparam CACTUS_Y = (SCREEN_HEIGHT - SCALED_HEIGHT) / 2;
	 parameter TRANSPARENT_COLOR = 24'h00F81F;


    wire in_sprite_x = (hcount >= CACTUS_X) &&
                       (hcount <  CACTUS_X + SCALED_WIDTH);
    wire in_sprite_y = (vcount >= CACTUS_Y) &&
                       (vcount <  CACTUS_Y + SCALED_HEIGHT);
    wire in_sprite   = in_sprite_x && in_sprite_y;

    wire [9:0] sprite_x_scaled = hcount - CACTUS_X;
    wire [9:0] sprite_y_scaled = vcount - CACTUS_Y;
    wire [9:0] sprite_x = sprite_x_scaled / SCALE;
    wire [9:0] sprite_y = sprite_y_scaled / SCALE;

    wire [12:0] pixel_offset = sprite_y * SPRITE_WIDTH + sprite_x; // 0..1023
    wire [12:0] rom_addr     = BASE_ADDR + pixel_offset;
	 
	 wire [4:0] r5 = sprite_data[15:11];
    wire [5:0] g6 = sprite_data[10:5];
    wire [4:0] b5 = sprite_data[4:0];
    
    wire [7:0] r8 = {r5, r5[4:2]};
    wire [7:0] g8 = {g6, g6[5:4]};
    wire [7:0] b8 = {b5, b5[4:2]};
    
    wire is_transparent = (sprite_data[15:0] == TRANSPARENT_COLOR[15:0]);

    always @(*) begin
        if (bright) begin
            if (in_sprite) begin
                sprite_addr = rom_addr;
                if (is_transparent) begin
					 pixel_opaque = 1'b0;
                    vga_r = BG_R;
                    vga_g = BG_G;
                    vga_b = BG_B;
                end else begin
					 pixel_opaque = 1'b1;
                    vga_r = r8;
                    vga_g = g8;
                    vga_b = b8;
                end
            end else begin
                sprite_addr = BASE_ADDR;
					 pixel_opaque = 1'b0;
                vga_r = BG_R;
                vga_g = BG_G;
                vga_b = BG_B;
            end
        end else begin
            sprite_addr = BASE_ADDR;
				pixel_opaque = 1'b0;
            vga_r = 8'h00;
            vga_g = 8'h00;
            vga_b = 8'h00;
        end
    end
endmodule
