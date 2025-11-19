`timescale 1ns / 1ps

module bitgen(
    input wire clk,
    input wire bright,
    input wire [9:0] hcount,
    input wire [9:0] vcount,
    output reg [2:0] rgb
);

// rectangle params
localparam STATIC_X = 270;
localparam STATIC_Y = 190;
localparam STATIC_W = 100;
localparam STATIC_H = 100;

localparam MOVE_W = 50;
localparam MOVE_H = 50;
reg [9:0] move_x;
localparam MOVE_Y = 50;
localparam MOVE_SPEED = 2;


always @(posedge clk) begin
    if (vcount == 0 && hcount == 0) begin
        if (move_x >= 640 - MOVE_W)
            move_x <= 0;
        else
            move_x <= move_x + MOVE_SPEED;
    end
end


always @(*) begin
    if (!bright) begin
        rgb = 3'b000;  // Black during blanking
    end else begin
        if (hcount >= STATIC_X && hcount < STATIC_X + STATIC_W &&
            vcount >= STATIC_Y && vcount < STATIC_Y + STATIC_H) begin
            rgb = 3'b011;  // cyan
        end
        else if (hcount >= move_x && hcount < move_x + MOVE_W &&
                 vcount >= MOVE_Y && vcount < MOVE_Y + MOVE_H) begin
            rgb = 3'b110;  // yellow
        end
        else begin
            rgb = 3'b001;  // Background is blue
        end
    end
end

endmodule