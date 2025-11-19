`timescale 1ns / 1ps
module vga_control
(
    input  wire clk,
    output reg  hsync,
    output reg  vsync,
    output wire bright,

    // this is the ONLY pixel clock output
    output wire pix_clk_out,

    output reg [9:0] hcount,
    output reg [9:0] vcount
);

reg [1:0] clkdiv;
reg pix_clk_internal;

// Clock divider: 100 MHz → 25 MHz
always @(posedge clk) begin
    clkdiv <= clkdiv + 1;
    pix_clk_internal <= clkdiv[1];
end

assign pix_clk_out = pix_clk_internal;


// ===============================
// VGA Timing
// ===============================

localparam H_VISIBLE = 10'd640,
           H_FRONT   = 10'd16,
           H_SYNC    = 10'd96,
           H_BACK    = 10'd48,
           H_TOTAL   = 10'd800;

localparam V_VISIBLE = 10'd480,
           V_FRONT   = 10'd10,
           V_SYNC    = 10'd2,
           V_BACK    = 10'd33,
           V_TOTAL   = 10'd525;

always @(posedge pix_clk_internal) begin
	  if (hcount == H_TOTAL - 1) begin
			hcount <= 0;
			vcount <= (vcount == V_TOTAL - 1) ? 0 : vcount + 1;
	  end else begin
			hcount <= hcount + 1;
	  end
end

always @(posedge pix_clk_internal) begin
    hsync <= ~((hcount >= H_VISIBLE + H_FRONT) &&
               (hcount <  H_VISIBLE + H_FRONT + H_SYNC));

    vsync <= ~((vcount >= V_VISIBLE + V_FRONT) &&
               (vcount <  V_VISIBLE + V_FRONT + V_SYNC));
end

assign bright = (hcount < H_VISIBLE) && (vcount < V_VISIBLE);

endmodule
