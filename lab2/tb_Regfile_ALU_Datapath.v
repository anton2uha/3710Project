moduel tb_Regfile_ALU_Datapath;

    reg clk;
    reg reset;

    // Initialize signals
    initial begin
        clk = 0;
        reset = 1;
    end

    // Generate clock
    always #5 clk = ~clk;

endmodule