`timescale 1ns/1ps
// fpga_top (switch-only, debounced)
// SW9 : MODE (0=DATA, 1=CTRL)  -- debounced
// SW8 : COMMIT in DATA mode     -- debounced (one clean pulse on 0->1)
// SW7..0 : 8-bit data (DATA mode)
// In CTRL mode: SW8..5=opcode, SW4=cin
module fpga_top(
  input        CLOCK_50,
  input  [9:0] SW,
  output [9:0] LEDR,                 // [4:0]=Flags, [9:6]=phase debug
  output [6:0] HEX0, HEX1, HEX2, HEX3
);
  // debounce SW9 (mode) and SW8 (commit)
  wire mode_level, mode_rise, mode_fall;
  wire com_level,  com_rise;  // commit uses only rising edge in DATA

  db_pulse #(.CNT_MAX(500_000)) u_db_mode ( // ~10ms @ 50MHz
    .clk(CLOCK_50), .din(SW[9]),
    .level(mode_level), .rise(mode_rise), .fall(mode_fall)
  );
  db_pulse #(.CNT_MAX(500_000)) u_db_commit(
    .clk(CLOCK_50), .din(SW[8]),
    .level(com_level), .rise(com_rise), .fall(/*unused*/)
  );

  // enter DATA when CTRL->DATA (clean falling edge of mode)
  wire enter_data   = mode_fall;           // 1->0
  // one clean commit pulse only in DATA mode and only on SW8 0->1
  wire commit_pulse = (~mode_level) & com_rise;

  // A/B registers and phase: 0:A_lo, 1:A_hi, 2:B_lo, 3:B_hi
  reg [15:0] A = 16'h0000, B = 16'h0000;
  reg [1:0]  phase = 2'd0;

  always @(posedge CLOCK_50) begin
    if (enter_data) phase <= 2'd0;                // reset to A_lo on re-enter DATA
    else if (commit_pulse) phase <= phase + 2'd1; // advance exactly one step

    if (commit_pulse) begin
      case (phase)
        2'd0: A[7:0]   <= SW[7:0];
        2'd1: A[15:8]  <= SW[7:0];
        2'd2: B[7:0]   <= SW[7:0];
        2'd3: B[15:8]  <= SW[7:0];
      endcase
    end
  end

  // CTRL registers: opcode / cin (latched while MODE=1)
  reg [3:0] opcode_r = 4'h0;
  reg       cin_r    = 1'b0;
  always @(posedge CLOCK_50) begin
    if (mode_level) begin          // in CTRL mode
      opcode_r <= SW[8:5];
      cin_r    <= SW[4];
    end
  end

  // ALU instance
  wire [15:0] C;
  wire [4:0]  Flags;               // [4]=Z, [3]=C, [2]=O, [1]=L, [0]=N
  alu uut (.A(A), .B(B), .C(C), .Opcode(opcode_r), .cin(cin_r), .Flags(Flags));

  // outputs
  hex4 disp(.value(C), .HEX0(HEX0), .HEX1(HEX1), .HEX2(HEX2), .HEX3(HEX3));
  assign LEDR[4:0] = Flags;
  // phase debug: 1000=A_lo, 0100=A_hi, 0010=B_lo, 0001=B_hi
  assign LEDR[9:6] = (phase==2'd0)?4'b1000 :
                     (phase==2'd1)?4'b0100 :
                     (phase==2'd2)?4'b0010 : 4'b0001;
endmodule

// debouncer with clean rise/fall pulses
module db_pulse #(parameter integer CNT_MAX = 500_000) ( // ~10ms @50MHz
  input  clk,
  input  din,                 // raw switch
  output level,               // debounced level
  output rise,                // 0->1 one-cycle pulse
  output fall                 // 1->0 one-cycle pulse
);
  // sync to clk
  reg [1:0] s; always @(posedge clk) s <= {s[0], din};
  // debounce
  reg [19:0] cnt = 0;
  reg        lvl = 1'b0;
  always @(posedge clk) begin
    if (s[1] == lvl) cnt <= 0;
    else begin
      cnt <= cnt + 1;
      if (cnt == CNT_MAX-1) begin
        lvl <= s[1];
        cnt <= 0;
      end
    end
  end
  
  // edge pulses
  reg lvl_d; always @(posedge clk) lvl_d <= lvl;
  assign level = lvl;
  assign rise  =  lvl & ~lvl_d;
  assign fall  = ~lvl &  lvl_d;
endmodule

// 16-bit -> four 7-seg (active-low)
module hex4(input [15:0] value,
            output [6:0] HEX0, HEX1, HEX2, HEX3);
  hex7 h0(value[3:0],   HEX0);
  hex7 h1(value[7:4],   HEX1);
  hex7 h2(value[11:8],  HEX2);
  hex7 h3(value[15:12], HEX3);
endmodule

// 4-bit -> 7-seg (active-low; segments = a b c d e f g) 
module hex7(input [3:0] d, output reg [6:0] seg);
  always @(*) begin
    case (d)
      4'h0: seg=7'b1000000; 4'h1: seg=7'b1111001; 4'h2: seg=7'b0100100; 4'h3: seg=7'b0110000;
      4'h4: seg=7'b0011001; 4'h5: seg=7'b0010010; 4'h6: seg=7'b0000010; 4'h7: seg=7'b1111000;
      4'h8: seg=7'b0000000; 4'h9: seg=7'b0010000; 4'hA: seg=7'b0001000; 4'hB: seg=7'b0000011;
      4'hC: seg=7'b1000110; 4'hD: seg=7'b0100001; 4'hE: seg=7'b0000110; 4'hF: seg=7'b0001110;
    endcase
  end
endmodule
