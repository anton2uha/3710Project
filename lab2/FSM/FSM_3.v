/* Secondary FSM for verifying AND, OR, XOR, NOT implementations
*/
`timescale 1ns/1ps
module FSM_3(
    input  wire clk,
    input  wire reset,
    output wire [15:0] out
);

reg  [3:0]  opcode, rdest, rsrc;
reg  [15:0] regEnable, wdata, immediate;
reg regFileWriteEnable, useImmediate;

initial begin
    opcode = 4'b0000;
    rdest = 4'd0;
    rsrc = 4'd0;
    regEnable = 16'b0;
    wdata = 16'b0;
    immediate = 16'b0;
    regFileWriteEnable  = 1'b0;
    useImmediate = 1'b0;
end

// ALU opcodes
parameter [3:0] AND_ = 4'b0001;
parameter [3:0] OR_  = 4'b0010;
parameter [3:0] XOR_ = 4'b0011;
parameter [3:0] NOT_ = 4'b1000;
parameter [3:0] NOP  = 4'b0000;

Regfile_ALU_Datapath my_dataPath (
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

// state encoding
parameter S0_SEED_R1 = 4'd0;
parameter S1_SEED_R2 = 4'd1;
parameter S2_AND     = 4'd2;
parameter S3_OR      = 4'd3;
parameter S4_XOR     = 4'd4;
parameter S5_NOT     = 4'd5;
parameter S6_HOLD    = 4'd6;

reg [3:0] state;

always @(posedge clk or negedge reset) begin
    if (!reset)
        state <= S0_SEED_R1;
    else begin
        case (state)
            S0_SEED_R1: state <= S1_SEED_R2;
            S1_SEED_R2: state <= S2_AND;
            S2_AND    : state <= S3_OR;
            S3_OR     : state <= S4_XOR;
            S4_XOR    : state <= S5_NOT;
            S5_NOT    : state <= S6_HOLD;
            S6_HOLD   : state <= S6_HOLD;
            default   : state <= S0_SEED_R1;
        endcase
    end
end

always @(*) begin
    opcode = NOP;
    rdest = 4'd0;
    rsrc = 4'd0;
    regEnable = 16'b0;
    wdata = 16'b0;
    regFileWriteEnable = 1'b0;
    useImmediate = 1'b0;
    immediate = 16'b0;

    case (state)

        // Fill r1 and r2 with  values
        S0_SEED_R1: begin
            wdata = 16'b0000111100001111; // 0x0F0F
            regFileWriteEnable = 1'b1;
            regEnable = 16'b0000000000000010; // r1
        end

        S1_SEED_R2: begin
            wdata = 16'b0000000011111111; // 0x00FF
            regFileWriteEnable = 1'b1;
            regEnable = 16'b0000000000000100; // r2
        end

        // ALU operations
        S2_AND: begin
            opcode = AND_;
            rdest = 4'd1; // r1
            rsrc = 4'd2; // r2
            regEnable = 16'b0000000000001000; // r3
        end

        S3_OR: begin
            opcode = OR_;
            rdest = 4'd1; // r1
            rsrc = 4'd2; // r2
            regEnable = 16'b0000000000010000; // r4
        end
        S4_XOR: begin
            opcode = XOR_;
            rdest = 4'd1; // r1
            rsrc = 4'd2; // r2
            regEnable = 16'b0000000000100000; // r5
        end
        S5_NOT: begin
            opcode = NOT_;
            rdest = 4'd5; // r5
            rsrc = 4'd5; // ignored by ALU
            regEnable = 16'b0000000001000000; // r6
        end

        S6_HOLD: begin
            // keep defaults
        end

    endcase
    
end

endmodule