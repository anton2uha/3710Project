module space_to_memory (
    input  wire        clk,
    input  wire        n_reset,

    // PS2 lines
    inout  wire        PS2_CLK,
    inout  wire        PS2_DAT,

    // RAM Port B
    output reg  [15:0] addr_b,
    output reg  [15:0] data_b,
    output reg         we_b
);

    // space key detector outputs
    wire space_pressed_pulse;
    wire space_is_down;

    // MOVI 0x03 => 0x0003
    localparam [15:0] INPUT_ADDR = 16'h00E0;

    // PS2 space key detector
    space_key_detector skd (
        .CLOCK_50          (clk),
        .n_reset           (n_reset),
        .PS2_CLK           (PS2_CLK),
        .PS2_DAT           (PS2_DAT),
        .space_pressed_pulse(),      // not used yet?
        .space_is_down     (space_is_down)
    );

    // write space_is_down every clk
    always @(posedge clk or negedge n_reset) begin
        if (!n_reset) begin
            addr_b <= INPUT_ADDR;
            data_b <= 16'h0000;
            we_b   <= 1'b0;
        end else begin
            addr_b <= INPUT_ADDR;
            // bit 0: space_is_down, 
            data_b <= {15'b0, space_is_down};
            we_b   <= 1'b1;   // write 
        end
    end

endmodule
