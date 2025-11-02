`timescale 1ns/1ps

module tb_FSM;

  parameter DATA_WIDTH = 16;
  parameter ADDR_WIDTH = 16;

  reg  clk;
  reg  reset;
  wire [DATA_WIDTH-1:0] q_a, q_b;

  // DUT
  FSM #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
  ) fsm_inst (
    .clk(clk),
    .reset(reset),
    .q_a(q_a),
    .q_b(q_b)
  );

  // clock
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // reset + run 
  initial begin
    reset = 0;
    #20;         
    reset = 1;   
    #500;        // run long enough to reach S9
    $finish;
  end

  
  initial begin
    $display(" time(ns) | st | we_a we_b | addr_a | addr_b | data_a | data_b |  q_a  |  q_b");
    $display("----------+----+----------+--------+--------+--------+--------+-------+-------");
    $monitor("%8t | %2d |   %1b    %1b | 0x%04h | 0x%04h | 0x%04h | 0x%04h | 0x%04h | 0x%04h",
             $time,
             fsm_inst.state,
             fsm_inst.we_a, fsm_inst.we_b,
             fsm_inst.addr_a, fsm_inst.addr_b,
             fsm_inst.data_a, fsm_inst.data_b,
             q_a, q_b);
  end

endmodule
