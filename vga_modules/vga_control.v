`timescale 1ns / 1ps

module vga_control(
    input wire clk,
    input wire reset,
    output reg hsync,
    output reg vsync,
    output wire bright,
    output reg [9:0] hcount,  // 0-799
    output reg [9:0] vcount   // 0-524
);

localparam H_VISIBLE = 640;
localparam H_FRONT   = 16;
localparam H_SYNC    = 96;
localparam H_BACK    = 48;
localparam H_TOTAL   = 800;

localparam V_VISIBLE = 480;
localparam V_FRONT   = 10;
localparam V_SYNC    = 2;
localparam V_BACK    = 33;
localparam V_TOTAL   = 525;

// Counters
always @(posedge clk or posedge reset) begin
    if (reset) begin
        hcount <= 0;
        vcount <= 0;
    end else begin
        if (hcount == H_TOTAL - 1) begin
            hcount <= 0;
            if (vcount == V_TOTAL - 1)
                vcount <= 0;
            else
                vcount <= vcount + 1;
        end else begin
            hcount <= hcount + 1;
        end
    end
end

//sync pulses
always @(posedge clk) begin
    hsync <= ~((hcount >= H_VISIBLE + H_FRONT) && 
               (hcount < H_VISIBLE + H_FRONT + H_SYNC));
    vsync <= ~((vcount >= V_VISIBLE + V_FRONT) && 
               (vcount < V_VISIBLE + V_FRONT + V_SYNC));
end

// Only high on visible
assign bright = (hcount < H_VISIBLE) && (vcount < V_VISIBLE);

endmodule