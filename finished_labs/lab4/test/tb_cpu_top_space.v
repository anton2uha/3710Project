`timescale 1ns / 1ps

// Simple CPU top testbench:
// - Run for 100 us
// - Assert reset for a few cycles
// - Send a PS/2 space make code (0x29) mid-simulation to exercise the space key path

module tb_cpu_top_space;

    // 50 MHz clock (20 ns period)
    reg clk;
    localparam integer CLK_HALF = 10;
    initial clk = 1'b0;
    always #CLK_HALF clk = ~clk;

    // Active-low reset
    reg reset;

    // PS/2 open-drain lines with weak pull-up
    tri1 PS2_CLK;
    tri1 PS2_DAT;
    reg kb_clk_drive_low;
    reg kb_dat_drive_low;
    assign PS2_CLK = kb_clk_drive_low ? 1'b0 : 1'bz;
    assign PS2_DAT = kb_dat_drive_low ? 1'b0 : 1'bz;

    // VGA outputs (unused in this TB)
    wire VGA_HS, VGA_VS, VGA_CLK, VGA_BLANK_N, VGA_SYNC_N;
    wire [7:0] VGA_R, VGA_G, VGA_B;
    wire space_led;

    // DUT
    cpu_top dut (
        .clk(clk),
        .reset(reset),
        .PS2_CLK(PS2_CLK),
        .PS2_DAT(PS2_DAT),
        .VGA_HS(VGA_HS),
        .VGA_VS(VGA_VS),
        .VGA_CLK(VGA_CLK),
        .VGA_BLANK_N(VGA_BLANK_N),
        .VGA_SYNC_N(VGA_SYNC_N),
        .VGA_R(VGA_R),
        .VGA_G(VGA_G),
        .VGA_B(VGA_B),
        .space_led(space_led)
    );

    // PS/2 timing: ~10 kHz clock (100 us period)
    localparam integer PS2_HALF = 50_000; // ns

    initial begin
        kb_clk_drive_low = 1'b0;
        kb_dat_drive_low = 1'b0;
        reset            = 1'b0; // assert reset (active low)

        // hold reset low for a few cycles
        repeat (5) @(posedge clk);
        reset = 1'b1;

        // wait a bit, then send space make code at ~40 us
        #(40_000);
        $display("[%0t ns] Sending PS/2 make code for SPACE (0x29)", $time);
        send_ps2_byte(8'h29);

        // run to 100 us total
        #(60_000);
        $display("[%0t ns] Done", $time);
        $stop;
    end

    // Drive one PS/2 bit (data stable while clock rises)
    task ps2_tick_bit;
        input bit_value;
    begin
        kb_clk_drive_low = 1'b1;                 // clock low
        kb_dat_drive_low = (bit_value == 1'b0);  // drive low for 0, float for 1
        #PS2_HALF;

        kb_clk_drive_low = 1'b0;                 // clock high
        #PS2_HALF;
    end
    endtask

    // Send a full PS/2 byte (start, 8 data bits LSB-first, odd parity, stop)
    task send_ps2_byte;
        input [7:0] data;
        integer i;
        reg parity;
    begin
        parity = ~(^data); // odd parity

        // ensure idle high
        kb_dat_drive_low = 1'b0;
        kb_clk_drive_low = 1'b0;
        #PS2_HALF;

        // Start bit (0)
        ps2_tick_bit(1'b0);

        // Data bits LSB-first
        for (i = 0; i < 8; i = i + 1)
            ps2_tick_bit(data[i]);

        // Parity bit
        ps2_tick_bit(parity);

        // Stop bit (1)
        ps2_tick_bit(1'b1);

        // Release lines
        kb_dat_drive_low = 1'b0;
        kb_clk_drive_low = 1'b0;
        #PS2_HALF;
    end
    endtask

endmodule
