`timescale 1ns/1ps
module tb_Regfile_ALU_Datapath;

  reg clk = 0, reset = 1;
  reg  [3:0]  opcode, rdest, rsrc;
  reg  [15:0] regEnable, wdata, immediate;
  reg         regFileWriteEnable, useImmediate;
  wire [15:0] out;

  Regfile_ALU_Datapath dut(
    .clk(clk), .reset(reset),
    .opcode(opcode), .rdest(rdest), .rsrc(rsrc),
    .regEnable(regEnable), .regFileWriteEnable(regFileWriteEnable),
    .wdata(wdata), .immediate(immediate), .useImmediate(useImmediate),
    .out(out)
  );

  always #5 clk = ~clk;
  initial $timeformat(-9,0," ns",7);

  // Prevents writing conflict
  task wr1(input [3:0] rd); begin
    regEnable = 16'h1 << rd; @(posedge clk);
    regEnable = 16'h0;       @(posedge clk);
  end endtask

  initial begin
    // init + reset
    opcode=0; rdest=0; rsrc=0; regEnable=0;
    regFileWriteEnable=0; wdata=0; immediate=0; useImmediate=0;
    repeat(2) @(posedge clk); reset=0; @(posedge clk);

    // preload r0=1, r1=3, r2=5 
    regFileWriteEnable=1;
    $display("[%t] write r0=0x0001",$time); wdata=16'h0001; wr1(0);
    $display("[%t] write r1=0x0003",$time); wdata=16'h0003; wr1(1);
    $display("[%t] write r2=0x0005",$time); wdata=16'h0005; wr1(2);
    regFileWriteEnable=0;

    // ADD: r1 = r1 + r2  (expect 0x0008)  
    opcode=4'b0101; rdest=4'd1; rsrc=4'd2; useImmediate=0;
    @(posedge clk); #1;
    $display("[%t] ADD r1=r1+r2 expect=0x0008  got=%h %s",
             $time, out, (out==16'h0008)?"PASS":"FAIL");
    wr1(1);
    opcode=4'b0000;  

    // ADD imm: r2 = r2 + 7 (expect 0x000C)
    opcode=4'b0101; rdest=4'd2; rsrc=4'd2; useImmediate=1; immediate=16'd7;
    @(posedge clk); #1;
    $display("[%t] ADD(imm) r2=r2+7 expect=0x000C  got=%h %s",
             $time, out, (out==16'h000C)?"PASS":"FAIL");
    wr1(2);
    opcode=4'b0000;

    // CMP: r1 - r2  (out depends on ALU; some designs flags-only)
    opcode=4'b1011; rdest=4'd1; rsrc=4'd2; useImmediate=0; regEnable=0;
    @(posedge clk); #1;
    $display("[%t] CMP r1-r2  out=%h", $time, out);
    opcode=4'b0000;

    // ASHU: r1 << 1 (expect 0x0010) assuming r0=1 is shift amount
    opcode=4'b1100; rdest=4'd1; rsrc=4'd0; useImmediate=0;
    @(posedge clk); #1;
    $display("[%t] ASHU r1<<1 expect=0x0010  got=%h %s",
             $time, out, (out==16'h0010)?"PASS":"FAIL");
    wr1(1);
    opcode=4'b0000;

    $finish;
  end
endmodule
