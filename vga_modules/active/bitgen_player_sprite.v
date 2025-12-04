// Player sprite: fixed X, animated frames, Y comes from game logic
`timescale 1ns / 1ps
module bitgen_player_sprite #(
    parameter SPRITE_WIDTH   = 32,
    parameter SPRITE_HEIGHT  = 32,
    parameter SCALE          = 3,
    parameter NUM_FRAMES     = 4,
    parameter BASE_ADDR      = 12'd0,      // base address in sprite ROM
    parameter SCREEN_WIDTH   = 640,
	 parameter DEBUG_SHOW_BG  = 1
)(
    input  wire        pix_clk,
    input  wire        bright,
    input  wire [9:0]  hcount,
    input  wire [9:0]  vcount,
    input  wire [15:0] sprite_data,        // from ROM
    output reg  [12:0] sprite_addr,        // to ROM
    output reg  [7:0]  vga_r,
    output reg  [7:0]  vga_g,
    output reg  [7:0]  vga_b,
    output reg         pixel_opaque,
    input  wire [9:0]  player_y
);

    // Scaled sprite size
    localparam SCALED_WIDTH   = SPRITE_WIDTH  * SCALE;
    localparam SCALED_HEIGHT  = SPRITE_HEIGHT * SCALE;
    localparam PIXELS_PER_FRAME = SPRITE_WIDTH * SPRITE_HEIGHT;

    // Center X on screen
    // localparam [9:0] PLAYER_X = ((SCREEN_WIDTH - SCALED_WIDTH) / 2) - 20;
    localparam [9:0] PLAYER_X = 0;

    localparam BG_R = 8'h88;
    localparam BG_G = 8'hCC;
    localparam BG_B = 8'h88;
	 localparam DEBUG_R = 8'hFF;  // ← ADD THESE
    localparam DEBUG_G = 8'h00;
    localparam DEBUG_B = 8'hFF;  // Magenta
    localparam [23:0] TRANSPARENT_COLOR = 24'h00F81F;

    // Animation control (only frames, no movement)
    reg [1:0]  current_frame;
    reg [25:0] anim_counter;
    localparam [25:0] ANIM_SPEED = 26'd5_000_000;  // ~5 FPS at 25 MHz

    initial begin
        current_frame = 2'd0;
        anim_counter  = 26'd0;
    end

    always @(posedge pix_clk) begin
        anim_counter <= anim_counter + 1'b1;
        if (anim_counter >= ANIM_SPEED) begin
            anim_counter <= 26'd0;
            if (current_frame >= NUM_FRAMES - 1)
                current_frame <= 2'd0;
            else
                current_frame <= current_frame + 1'b1;
        end
    end

    wire in_sprite_x = (hcount >= PLAYER_X) &&
                       (hcount <  PLAYER_X + SCALED_WIDTH);
    wire in_sprite_y = (vcount >= player_y) &&
                       (vcount <  player_y + SCALED_HEIGHT);
    wire in_sprite   = in_sprite_x && in_sprite_y;

    wire [9:0] sprite_x_scaled = hcount - PLAYER_X;
    wire [9:0] sprite_y_scaled = vcount - player_y;

    // Flip horizontally like your original (optional)
    wire [9:0] sprite_x = (SPRITE_WIDTH - 1) - (sprite_x_scaled / SCALE);
    wire [9:0] sprite_y = sprite_y_scaled / SCALE;

    wire [12:0] frame_offset = current_frame * PIXELS_PER_FRAME;
    wire [12:0] pixel_offset = sprite_y * SPRITE_WIDTH + sprite_x;
    wire [12:0] local_addr   = frame_offset + pixel_offset;
    wire [12:0] rom_addr     = BASE_ADDR + local_addr;

    wire [4:0] r5 = sprite_data[15:11];
    wire [5:0] g6 = sprite_data[10:5];
    wire [4:0] b5 = sprite_data[4:0];

    wire [7:0] r8 = {r5, r5[4:2]};
    wire [7:0] g8 = {g6, g6[5:4]};
    wire [7:0] b8 = {b5, b5[4:2]};

    wire is_transparent = (sprite_data[15:0] == TRANSPARENT_COLOR[15:0]);

    always @(*) begin
        if (!bright) begin
            // Outside active video
            sprite_addr  = BASE_ADDR;
            pixel_opaque = 1'b0;
            vga_r        = 8'h00;
            vga_g        = 8'h00;
            vga_b        = 8'h00;
        end else if (in_sprite) begin
            sprite_addr = rom_addr;
            if (is_transparent) begin
                pixel_opaque = DEBUG_SHOW_BG ? 1'b1 : 1'b0;  // ← MODIFIED
                vga_r        = DEBUG_SHOW_BG ? DEBUG_R : BG_R;  // ← MODIFIED
                vga_g        = DEBUG_SHOW_BG ? DEBUG_G : BG_G;  // ← MODIFIED
                vga_b        = DEBUG_SHOW_BG ? DEBUG_B : BG_B;  // ← MODIFIED
            end else begin
                pixel_opaque = 1'b1;
                vga_r        = r8;
                vga_g        = g8;
                vga_b        = b8;
            end
        end else begin
            sprite_addr  = BASE_ADDR;  // don't care when not in sprite
            pixel_opaque = 1'b0;
            vga_r        = BG_R;
            vga_g        = BG_G;
            vga_b        = BG_B;
        end
    end

endmodule
