// Single-sprite helper that produces RAM read addresses and colors from RAM data.
// This version does NOT own any memory; it relies on an external arbiter/BRAM port.
`timescale 1ns / 1ps
module ian_rework_bitgen_sprite #(
    parameter integer ADDR_WIDTH    = 16,
    parameter integer SPRITE_WIDTH  = 32,
    parameter integer SPRITE_HEIGHT = 32,
    parameter integer SCALE         = 3,
    parameter [ADDR_WIDTH-1:0] BASE_ADDR = {ADDR_WIDTH{1'b0}},
    // Transparent color in RGB565 (matches prior modules)
    parameter [15:0] TRANSPARENT_RGB565 = 16'hF81F,
    // Background color when this sprite is not active
    parameter [7:0] BG_R = 8'h88,
    parameter [7:0] BG_G = 8'hCC,
    parameter [7:0] BG_B = 8'h88
)(
    input  wire                   pix_clk,
    input  wire                   bright,
    input  wire [9:0]             hcount,
    input  wire [9:0]             vcount,
    // Position from metadata cache
    input  wire [9:0]             pos_x,
    input  wire [9:0]             pos_y,
    // RAM return data for THIS sprite when data_valid=1
    input  wire [15:0]            pix_data,
    input  wire                   data_valid,
    // Outputs
    output reg                    hit,          // sprite covers current pixel
    output reg  [ADDR_WIDTH-1:0]  req_addr,     // address to fetch for this pixel
    output reg  [7:0]             vga_r,
    output reg  [7:0]             vga_g,
    output reg  [7:0]             vga_b,
    output reg                    opaque
);

    localparam integer SCALED_WIDTH  = SPRITE_WIDTH  * SCALE;
    localparam integer SCALED_HEIGHT = SPRITE_HEIGHT * SCALE;
    localparam integer PIXELS_PER_SPRITE = SPRITE_WIDTH * SPRITE_HEIGHT;

    wire in_sprite_x = (hcount >= pos_x) && (hcount < pos_x + SCALED_WIDTH);
    wire in_sprite_y = (vcount >= pos_y) && (vcount < pos_y + SCALED_HEIGHT);
    wire in_sprite   = in_sprite_x && in_sprite_y;

    // Local coordinates
    wire [9:0] sprite_x_scaled = hcount - pos_x;
    wire [9:0] sprite_y_scaled = vcount - pos_y;
    wire [9:0] sprite_x        = sprite_x_scaled / SCALE;
    wire [9:0] sprite_y        = sprite_y_scaled / SCALE;

    wire [ADDR_WIDTH-1:0] pixel_offset = sprite_y * SPRITE_WIDTH + sprite_x; // fits in 13 bits for 32x32

    // Address request for this pixel
    always @(*) begin
        hit      = bright && in_sprite;
        req_addr = BASE_ADDR + pixel_offset;
    end

    // Color path (driven when the top-level tells us the returned data matches this sprite)
    wire [4:0] r5 = pix_data[15:11];
    wire [5:0] g6 = pix_data[10:5];
    wire [4:0] b5 = pix_data[4:0];

    wire [7:0] r8 = {r5, r5[4:2]};
    wire [7:0] g8 = {g6, g6[5:4]};
    wire [7:0] b8 = {b5, b5[4:2]};

    always @(*) begin
        if (!data_valid || !bright) begin
            opaque = 1'b0;
            vga_r  = BG_R;
            vga_g  = BG_G;
            vga_b  = BG_B;
        end else if (pix_data == TRANSPARENT_RGB565) begin
            opaque = 1'b0;
            vga_r  = BG_R;
            vga_g  = BG_G;
            vga_b  = BG_B;
        end else begin
            opaque = 1'b1;
            vga_r  = r8;
            vga_g  = g8;
            vga_b  = b8;
        end
    end

endmodule
