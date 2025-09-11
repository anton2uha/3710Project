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

    // TODO: Test each opcode with imm and regs

    // ADD   = 4'b0101;
    // TODO: test imm
    // TODO: test reg

    // CMP   = 4'b1011;
    // TODO: test imm
    // TODO: test reg

    // ASHU  = 4'b1100;
    // TODO: test imm
    // TODO: test reg


endmodule