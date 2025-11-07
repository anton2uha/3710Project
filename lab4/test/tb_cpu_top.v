`timescale 1ns / 1ps
module tb_cpu_top();

    reg clk;
    reg reset;

    wire [15:0] out;
    cpu_top uut (
        .clk(clk),
        .reset(reset),
        .out(out)
    );
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10 time units clock period
    end

    initial begin
        // Initialize reset
        reset = 0;
        #15;
        reset = 1;

        #500;
        $stop;
    end

endmodule