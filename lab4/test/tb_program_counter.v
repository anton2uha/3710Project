// module program_counter(
// 	input en, clk, rst_n,
// 	output reg [15:0] pc
// );
`timescale 1ns / 1ps
module tb_program_counter;
    reg en;
    reg clk;
    reg rst_n;
    wire [15:0] pc;
    
    program_counter uut (
        .en(en),
        .clk(clk),
        .rst_n(rst_n),
        .pc(pc)
    );
    
    // Clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10 time units clock period
    end

    // Monitor values
    initial begin
        $monitor("Time: %0t | en: %b | rst_n: %b | pc: %d", $time, en, rst_n, pc);
    end

    // Test sequence
    initial begin
        rst_n = 0;
        en = 0;
        #15;
    
        rst_n = 1;
        #10;
    
        // Enable counting
        en = 1;
        #50; // Let it count for a while
    
        // Disable counting
        en = 0;
        #20; // Hold for a while
    
        // Re-enable counting
        en = 1;
        #30; // Let it count again
    
        // Finish simulation
        $finish;
    end

endmodule 