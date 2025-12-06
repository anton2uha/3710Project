`timescale 1ns / 1ps

// Testbench: space_key_detector_tb
// Drives a PS/2 make code for the space key (0x29) into the DUT.

module space_key_detector_tb;

    // 50 MHz system clock
    reg CLOCK_50;
    localparam integer CLK_HALF_PERIOD = 10; // 20 ns period
    initial CLOCK_50 = 1'b0;
    always #(CLK_HALF_PERIOD) CLOCK_50 = ~CLOCK_50;

    // Active-low reset
    reg n_reset;

    // PS/2 lines are open-drain with pull-ups
    tri1 PS2_CLK;
    tri1 PS2_DAT;
    reg kb_clk_drive_low;
    reg kb_dat_drive_low;
    assign PS2_CLK = kb_clk_drive_low ? 1'b0 : 1'bz;
    assign PS2_DAT = kb_dat_drive_low ? 1'b0 : 1'bz;

    // DUT outputs
    wire space_pressed_pulse;
    wire space_is_down;

    // Device Under Test
    space_key_detector dut (
        .CLOCK_50           (CLOCK_50),
        .n_reset            (n_reset),
        .PS2_CLK            (PS2_CLK),
        .PS2_DAT            (PS2_DAT),
        .space_pressed_pulse(space_pressed_pulse),
        .space_is_down      (space_is_down)
    );

    // PS/2 timing (10 kHz clock -> 100 us period, 50 us half-period)
    localparam integer PS2_HALF_PERIOD = 50_000;

    initial begin
        // Defaults
        kb_clk_drive_low = 1'b0;
        kb_dat_drive_low = 1'b0;
        n_reset          = 1'b0;

        // Reset pulse
        repeat (5) @(posedge CLOCK_50);
        n_reset = 1'b1;

        // Allow DUT to settle
        #(PS2_HALF_PERIOD * 2);

        $display("[%0t ns] Sending space make code (0x29)", $time);
        send_ps2_byte(8'h29);

        // Expect a single-cycle pulse when the make code arrives
        @(posedge space_pressed_pulse);
        $display("[%0t ns] space_pressed_pulse asserted, space_is_down=%b", $time, space_is_down);

        // space_is_down should remain high after the make code
        #(PS2_HALF_PERIOD * 2);
        if (!space_is_down) begin
            $fatal(1, "[%0t ns] ERROR: space_is_down deasserted after make code", $time);
        end else begin
            $display("[%0t ns] PASS: space_is_down remains asserted after make code", $time);
        end

        #(PS2_HALF_PERIOD * 4);
        $stop;
    end

    // Drive one PS/2 bit (data stable while clock rises)
    task ps2_tick_bit;
        input bit_value;
    begin
        kb_clk_drive_low = 1'b1;                 // clock low phase
        kb_dat_drive_low = (bit_value == 1'b0);  // drive low for 0, release for 1
        #PS2_HALF_PERIOD;

        kb_clk_drive_low = 1'b0;                 // clock high phase
        #PS2_HALF_PERIOD;
    end
    endtask

    // Send a full PS/2 byte (start, 8 data bits LSB-first, odd parity, stop)
    task send_ps2_byte;
        input [7:0] data;
        integer i;
        reg parity;
    begin
        parity = ~(^data); // odd parity bit

        // Idle high before the frame
        kb_dat_drive_low = 1'b0;
        kb_clk_drive_low = 1'b0;
        #PS2_HALF_PERIOD;

        // Start bit (0)
        ps2_tick_bit(1'b0);

        // Data bits LSB-first
        for (i = 0; i < 8; i = i + 1) begin
            ps2_tick_bit(data[i]);
        end

        // Parity bit
        ps2_tick_bit(parity);

        // Stop bit (1)
        ps2_tick_bit(1'b1);

        // Release the bus
        kb_dat_drive_low = 1'b0;
        kb_clk_drive_low = 1'b0;
        #PS2_HALF_PERIOD;
    end
    endtask

endmodule

