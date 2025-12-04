// Scrolling Background - Single 180x180 Image Scaled to Fill Screen
`timescale 1ns / 1ps
module bitgen_background_sprite #(
    parameter BG_WIDTH       = 180,
    parameter BG_HEIGHT      = 180,
    parameter BASE_ADDR      = 17'd5120,
    parameter SCREEN_WIDTH   = 640,
    parameter SCREEN_HEIGHT  = 480
)(
    input  wire        pix_clk,
    input  wire        bright,
    input  wire [9:0]  hcount,
    input  wire [9:0]  vcount,
    input  wire [15:0] bg_data,
    output reg  [16:0] bg_addr,
    output reg  [7:0]  vga_r,
    output reg  [7:0]  vga_g,
    output reg  [7:0]  vga_b
);
    localparam PIXELS_PER_IMAGE = BG_WIDTH * BG_HEIGHT;  // 32,400 pixels
    
    // Calculate scale factors
    // 640 / 180 ≈ 3.56, 480 / 180 ≈ 2.67
    // We'll use integer division for scaling
    localparam SCALE_X = SCREEN_WIDTH / BG_WIDTH;   // 640/180 = 3
    localparam SCALE_Y = SCREEN_HEIGHT / BG_HEIGHT; // 480/180 = 2
    
    // Default background color
    localparam BG_R = 8'h88;
    localparam BG_G = 8'hCC;
    localparam BG_B = 8'h88;
    
    localparam [23:0] TRANSPARENT_COLOR = 24'h00F81F;
    
    // Scrolling control
    reg [15:0] scroll_offset;  // Horizontal scroll position in pixels
    reg [25:0] scroll_counter;
    
    // Scroll speed (slower than sprite for parallax effect)
    parameter SCROLL_SPEED = 26'd1600000;
    
    initial begin
        scroll_offset = 16'd0;
        scroll_counter = 26'd0;
    end
    
    // Update scroll position
    always @(posedge pix_clk) begin
    scroll_counter <= scroll_counter + 1;
    if (scroll_counter >= SCROLL_SPEED) begin
        scroll_counter <= 26'd0;

        if (scroll_offset >= BG_WIDTH - 1) begin
            scroll_offset <= 16'd0;
            flip_phase <= ~flip_phase;  // toggle each full image cycle
        end else begin
            scroll_offset <= scroll_offset + 1;
        end
    end
end
    
    // Scale down screen coordinates to background coordinates
    wire [9:0] bg_x_raw = hcount / SCALE_X;  // Map 0-639 to 0-179
    localparam V_OFFSET = (SCREEN_HEIGHT - BG_HEIGHT * SCALE_Y) / 2; // (480-360)/2=60

		wire [9:0] bg_y_raw =
			 (vcount < V_OFFSET || vcount >= V_OFFSET + BG_HEIGHT * SCALE_Y) ?
				  10'd0 : // or leave as background color
				  (vcount - V_OFFSET) / SCALE_Y;

    
    // Apply horizontal scrolling (wrap around)
    wire [9:0] bg_x_scrolled = (bg_x_raw + scroll_offset) % BG_WIDTH;
		wire [9:0] bg_x_flipped  = (BG_WIDTH - 1) - bg_x_scrolled;

		wire [9:0] bg_x = flip_phase ? bg_x_flipped : bg_x_scrolled;
		wire [9:0] bg_y = bg_y_raw;

    
    // Calculate ROM address
    wire [16:0] pixel_offset = bg_y * BG_WIDTH + bg_x;
    wire [16:0] calc_addr = BASE_ADDR + pixel_offset;
    
    // RGB565 to RGB888 conversion
    wire [4:0] r5 = bg_data[15:11];
    wire [5:0] g6 = bg_data[10:5];
    wire [4:0] b5 = bg_data[4:0];
    
    wire [7:0] r8 = {r5, r5[4:2]};
    wire [7:0] g8 = {g6, g6[5:4]};
    wire [7:0] b8 = {b5, b5[4:2]};
    
    wire is_transparent = (bg_data[15:0] == TRANSPARENT_COLOR[15:0]);
	 
	 reg flip_phase;  // 0 = normal, 1 = flipped

	initial begin
		 flip_phase = 1'b0;
	end
    
    always @(*) begin
        if (bright) begin
            bg_addr = calc_addr;
            
            if (is_transparent) begin
                vga_r = BG_R;
                vga_g = BG_G;
                vga_b = BG_B;
            end else begin
                vga_r = r8;
                vga_g = g8;
                vga_b = b8;
            end
        end else begin
            bg_addr = BASE_ADDR;
            vga_r = 8'h00;
            vga_g = 8'h00;
            vga_b = 8'h00;
        end
    end
endmodule