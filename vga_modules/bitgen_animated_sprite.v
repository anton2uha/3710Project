// Animated Sprite with Horizontal Movement
`timescale 1ns / 1ps
module bitgen_animated_sprite #(
    parameter SPRITE_WIDTH   = 32,
    parameter SPRITE_HEIGHT  = 32,
    parameter SCALE          = 3,
    parameter NUM_FRAMES     = 4,
    parameter BASE_ADDR      = 12'd0
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
    
    localparam SCALED_WIDTH = SPRITE_WIDTH * SCALE;
    localparam SCALED_HEIGHT = SPRITE_HEIGHT * SCALE;
    localparam PIXELS_PER_FRAME = SPRITE_WIDTH * SPRITE_HEIGHT;
    
    parameter SCREEN_WIDTH = 640;
    parameter SCREEN_HEIGHT = 480;
	 parameter SPRITE_Y = (SCREEN_HEIGHT - SCALED_HEIGHT) / 2;
    
    parameter BG_R = 8'h88;
    parameter BG_G = 8'hcc;
    parameter BG_B = 8'h88;
    
    parameter TRANSPARENT_COLOR = 24'h00F81F;
    
    // Movement and animation control
    reg [9:0] sprite_x_pos;
    reg [1:0] current_frame;
    reg [25:0] move_counter;
    reg [25:0] anim_counter;
    
    parameter MOVE_SPEED = 26'd200000;
    parameter ANIM_SPEED = 26'd5000000;   // 5 FPS => 25MHz / 5 = 5,000,000 clocks per frame
    
    initial begin
		  sprite_x_pos = 10'd0;
        current_frame = 2'd0;
        move_counter = 26'd0;
        anim_counter = 26'd0;
    end
    
    always @(posedge pix_clk) begin
        move_counter <= move_counter + 1;
        if (move_counter >= MOVE_SPEED) begin
            move_counter <= 26'd0;
            // LEFT to RIGHT
            if (sprite_x_pos >= SCREEN_WIDTH - SCALED_WIDTH)
                sprite_x_pos <= 10'd0;
            else
                sprite_x_pos <= sprite_x_pos + 1;
           
//            if (sprite_x_pos == 0)
//                sprite_x_pos <= SCREEN_WIDTH - SCALED_WIDTH;
//            else
//                sprite_x_pos <= sprite_x_pos - 1;
        end
        
        anim_counter <= anim_counter + 1;
        if (anim_counter >= ANIM_SPEED) begin
            anim_counter <= 26'd0;
            
            // Cycle through frames
            if (current_frame >= NUM_FRAMES - 1)
                current_frame <= 2'd0;
            else
                current_frame <= current_frame + 1;
        end
    end
    
    wire in_sprite_x = (hcount >= sprite_x_pos) && 
                       (hcount < sprite_x_pos + SCALED_WIDTH);
    wire in_sprite_y = (vcount >= SPRITE_Y) && 
                       (vcount < SPRITE_Y + SCALED_HEIGHT);
    wire in_sprite = in_sprite_x && in_sprite_y;
    
    wire [9:0] sprite_x_scaled = hcount - sprite_x_pos;
    wire [9:0] sprite_y_scaled = vcount - SPRITE_Y;
    
    wire [9:0] sprite_x = (SPRITE_WIDTH - 1) - (sprite_x_scaled / SCALE);
    wire [9:0] sprite_y = sprite_y_scaled / SCALE;
    
    wire [12:0] frame_offset = current_frame * PIXELS_PER_FRAME;
    wire [12:0] pixel_offset = sprite_y * SPRITE_WIDTH + sprite_x;
    wire [12:0] local_addr   = frame_offset + pixel_offset;      // 0..4095
    wire [12:0] rom_addr     = BASE_ADDR + local_addr;
    
    // RGB565 to RGB888 conversion
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