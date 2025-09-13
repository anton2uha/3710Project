`timescale 1ns / 1ps

module tb_Regfile_ALU_Datapath;

    // inputs
    reg clk, reset;
    reg [3:0] opcode, rdest, rsrc;
    reg [15:0] regEnable, wdata, immediate;
    reg regFileWriteEnable, useImmediate;

    // output
    wire [15:0] out;

    // Instantiation
    Regfile_ALU_Datapath dut (
        .clk(clk),
        .reset(reset),
        .opcode(opcode),
        .rdest(rdest),
        .rsrc(rsrc),
        .regEnable(regEnable),
        .regFileWriteEnable(regFileWriteEnable),
        .wdata(wdata),
        .immediate(immediate),
        .useImmediate(useImmediate),
        .out(out)
    );



	 initial clk = 0;
	 always #5 clk = ~clk;
	 
    initial begin
        // Initialize all signals and apply reset
        $display("Initializing");
        opcode = 0;
        rdest = 0;
        rsrc = 0;
        regEnable = 0;
        regFileWriteEnable = 0;
        wdata = 0;
        immediate = 0;
        useImmediate = 0;
        
        reset = 1;
        #10; // Wait for one clock cycle to apply reset
        reset = 0;
        #10; // Let the circuit settle

        // Preload registers R0, R1, and R2
        $display("Preloading registers R0, R1, R2");
        
        // Load R0 = 1
        regFileWriteEnable = 1;
        wdata = 16'h0001;
        regEnable = 16'h1; // Enable write to R0
        #10; 
        
        // Load R1 = 3
        wdata = 16'h0003;
        regEnable = 16'h2; // Enable write to R1
        #10; 
        
        // Load R2 = 5
        wdata = 16'h0005;
        regEnable = 16'h4; // Enable write to R2
        #10; 
        
        regFileWriteEnable = 0; // Disable further writes
        regEnable = 16'h0;

        // Test ADD instruction: R1 = R1 + R2 (expect 0x0008)
        $display("[%t] Testing ADD: R1 = R1 + R2", $time);
        opcode = 4'b0101;
        rdest = 4'd1;
        rsrc = 4'd2;
        useImmediate = 0;
        
        #5; // Wait for combinational logic to propagate
        $display("[%t] ADD result: Expected=0x0008, Got=0x%h -> %s",
                 $time, out, (out == 16'h0008) ? "PASS" : "FAIL");

        // Write the result back to R1
        $display("[%t] Writing result back to R1", $time);
        regFileWriteEnable = 1;
        wdata = out;
        regEnable = 16'h2; // Write to R1
        #10; 
        
        regFileWriteEnable = 0;
        regEnable = 16'h0;

        // Test ADD with immediate: R2 = R2 + 7 (expect 0x000C)
        $display("[%t] Testing ADD (imm): R2 = R2 + 7", $time);
        opcode = 4'b0101;
        rdest = 4'd2;
        rsrc = 4'd2;
        useImmediate = 1;
        immediate = 16'd7;
        
        #5;
        $display("[%t] ADD(imm) result: Expected=0x000C, Got=0x%h -> %s",
                 $time, out, (out == 16'h000C) ? "PASS" : "FAIL");
        
        // Write the result back to R2
        $display("[%t] Writing result back to R2", $time);
        regFileWriteEnable = 1;
        wdata = out;
        regEnable = 16'h4; // Write to R2
        #10;
        regFileWriteEnable = 0;
        regEnable = 16'h0;

        // Test CMP: R1 - R2 (expect 0x0004 since R1=8, R2=12)
        $display("[%t] Testing CMP: R1 - R2", $time);
        opcode = 4'b1011; // Assuming 1011 is CMP
        rdest = 4'd1;
        rsrc = 4'd2;
        useImmediate = 0;
        
        #5;
        $display("[%t] CMP result: Out=0x%h", $time, out);

        // Test ASHU: R1 = R1 << 1 (expect 0x0010, since R1 is now 8 from ADD)
        $display("[%t] Testing ASHU: R1 = R1 << 1", $time);
        opcode = 4'b1100; // Assuming 1100 is ASHU
        rdest = 4'd1;
        rsrc = 4'd0; // R0 holds the shift amount (1)
        useImmediate = 0;
        
        #5;
        $display("[%t] ASHU result: Expected=0x0010, Got=0x%h -> %s",
                 $time, out, (out == 16'h0010) ? "PASS" : "FAIL");

        $finish;
    end
endmodule
