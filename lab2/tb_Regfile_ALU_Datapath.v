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

    // ADDU  = 4'b0110;
    // TODO: test imm
    // TODO: test reg

    // ADDC  = 4'b0111;
    // TODO: test imm
    // TODO: test reg

    // SUB   = 4'b1001;
    // TODO: test imm
    // TODO: test reg

    // SUBC  = 4'b1010;
    // TODO: test imm
    // TODO: test reg

    // CMP   = 4'b1011;
    // TODO: test imm
    // TODO: test reg

    // AND   = 4'b0001;
    // TODO: test imm
    // TODO: test reg

    // OR    = 4'b0010;
    // TODO: test imm
    // TODO: test reg

    // XOR   = 4'b0011;
    // TODO: test imm
    // TODO: test reg

    // LSH   = 4'b0100;
    // TODO: test imm
    // TODO: test reg

    // NOT   = 4'b1000;
    // TODO: test imm
    // TODO: test reg

    // ASHU  = 4'b1100;
    // TODO: test imm
    // TODO: test reg

    // NOP   = 4'b0000;
    // TODO: test imm
    // TODO: test reg
    

endmodule