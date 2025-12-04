module sprite_rom_dp #(
    parameter DATA_WIDTH = 16,
    parameter ADDR_WIDTH = 16       // enough for 0..8191
)(
    input  wire                   clk,
    input  wire [ADDR_WIDTH-1:0]  addr_a,
    input  wire [ADDR_WIDTH-1:0]  addr_b,
    output wire [DATA_WIDTH-1:0]  q_a,
    output wire [DATA_WIDTH-1:0]  q_b
);

    // Reuse your true_dual_port_ram_single_clock as ROM
    true_dual_port_ram_single_clock_vga #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) ram_inst (
        .data_a({DATA_WIDTH{1'b0}}), // unused for ROM
        .data_b({DATA_WIDTH{1'b0}}),
        .addr_a(addr_a),
        .addr_b(addr_b),
        .we_a(1'b0),                 // disable writes
        .we_b(1'b0),
        .clk(clk),
        .q_a(q_a),
        .q_b(q_b)
    );

endmodule
