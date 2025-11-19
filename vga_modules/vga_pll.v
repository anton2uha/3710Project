module vga_pll (
    input  wire inclk0,     // 50 MHz input
    output wire c0          // 25.175 MHz output
);

    altpll #(
        .operation_mode("NORMAL"),
        .inclk0_input_frequency(20000),  // 20,000 ps = 50 MHz
        .clk0_divide_by(40),
        .clk0_multiply_by(2014),
        .clk0_duty_cycle(50),
        .clk0_phase_shift("0")
    ) pll_inst (
        .inclk({1'b0, inclk0}),
        .clk({c0})
    );

endmodule
