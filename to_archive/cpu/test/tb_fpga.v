`timescale 1ns / 1ps
module tb_fpga;
    // provide a clock and reset to the to_fpga_lab4 module
    reg clk;
    reg reset;
    wire [0:6] seven_seg, seven_seg2, seven_seg3, seven_seg4;

    to_fpga_lab4 uut (
        .clk(clk),
        .reset(reset),
        .seven_seg(seven_seg),
        .seven_seg2(seven_seg2),
        .seven_seg3(seven_seg3),
        .seven_seg4(seven_seg4)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10 ns clock period
    end
    // Test sequence
    initial begin
        // Initialize reset
        reset = 0;
        #12; // Hold reset for a few clock cycles
        reset = 1;
        #1000; // Run simulation for a while
        $stop;
    end

endmodule