// Control and decoder FSM from instruction opcodes following the CR16a architecture

/*
    List of all control signals we need to account for

    ALU:
        - A ()
        - B ()
        - Opcode
        - cin
    Regfile:
        - opcode [4bit]
        - rdest [4bit]
        - rsrc [4bit]
        - regenable [16bit]
        - regFileWriteEnable 
        - wdata [16bit]
        - immediate [16bit]
        - useImmediate

    List of opcodes so far:

        parameter ADD   = 4'b0101;
        parameter ADDU  = 4'b0110;
        parameter ADDC  = 4'b0111;
        parameter SUB   = 4'b1001;
        parameter SUBC  = 4'b1010;
        parameter CMP   = 4'b1011;
        parameter AND   = 4'b0001;
        parameter OR    = 4'b0010;
        parameter XOR   = 4'b0011;
        parameter MOV   = 4'b1101; // havent implemented yet
        parameter LSH   = 4'b0100;
        parameter NOT   = 4'b1000;
        parameter ASHU  = 4'b1100;
        parameter NOP   = 4'b0000;

*/

`timescale 1ns / 1ps

module control_and_decoder #(
    parameter [3:0] instrs = 4'd13 // number of instructions to execute before pausing
)(
    input  wire        clk,
    input  wire        reset,     
    input  wire [4:0]  flags,
    input  wire [15:0] instr,  
    input  wire [15:0] ir_reg,

    output reg         pc_en,         // to do PC+1 
    output reg         pc_mux_ctrl,   // PC mux cntrl
    output reg         LS_ctrl,
    output reg         ir_en,         // IR <= DOUT during S1
    output reg         reg_we,        // regfile write enable
    output reg         imm_en,        // 0: B=Rdest (RR), 1: B=Imm 
    output reg         alu_mux_ctrl,  // not used yet
    output reg  [3:0]  op,            // opcode (mapped from instr[12:9])
    output reg  [3:0]  rsrc,          // src reg index  (instr[4:1])
    output reg  [3:0]  rdest,         // dest reg index (instr[8:5])
    output reg  [7:0]  imm8,        
    output reg  [15:0] reg_en,
    output reg  [15:0] disp
);

    // States
    parameter S0 = 3'd0; // fetch stage
    parameter S1 = 3'd1; // decode stage
    parameter S2 = 3'd2; // r-type: execution + writeback
    parameter S3 = 3'd3; // store
    parameter S4 = 3'd4; // load addr
    parameter S5 = 3'd5; // load wb

    parameter CMP = 4'b1011;
    parameter NOP = 4'b0000;

    reg [2:0] state;
    integer i = 0;

    wire paused = (state == S2) && (i >= instrs);

    // State machine
    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            state <= S0;
            i     <= 0;
        end else begin 
            case (state)
                S0: begin
                    state <= S1;
                    if (!paused) i <= i + 1;
                end
                
                S1: begin
                    if (instr[15:12] == 4'b0100 && instr[7:4] == 4'b0000) 
                        state <= S4;
                    else 
                        state <= S2;
                end
                
                S2: state <= (paused) ? S2 : S0;
                S4: state <= S5;
                S5: state <= S0;
                
                default: state <= S0;
            endcase
        end
    end

    // Output logic
    always @(*) begin
        case (state)
            S0: begin 
                // ALU ctrls
                rsrc         = 0;
                rdest        = 0;
                op           = 4'd0;
                imm8         = 8'd0;
                imm_en       = 0;
                alu_mux_ctrl = 0;
                
                // Reg ctrls
                reg_en = 16'd0;
                reg_we = 0;
                
                // PC ctrls
                pc_en       = 0;
                pc_mux_ctrl = 0;
                disp        = 16'd0;
                
                // LOAD/STORE ctrls
                LS_ctrl = 0;
                ir_en   = 0;
            end
            
            S1: begin
                // ALU ctrls
                rsrc         = instr[3:0];
                rdest        = instr[11:8];
                op           = 4'd0;
                imm8         = instr[7:0];
                imm_en       = 0;
                alu_mux_ctrl = 0;
                
                // Reg ctrls
                reg_en = 16'd0;
                reg_we = 0;
                
                // PC ctrls
                pc_en       = 0;
                pc_mux_ctrl = 0;
                disp        = 16'd0;
                
                // LOAD/STORE ctrls
                LS_ctrl = 0;
                ir_en   = 0;

                if (instr[15:12] == 4'b0000) begin
                    op = instr[7:4];
                end else begin 
                    op     = instr[15:12];
                    imm_en = 1; 
                end
                
                // LOAD instruction
                if (instr[15:12] == 4'b0100 && instr[7:4] == 4'b0000) 
                    ir_en = 1;
            end
            
            S2: begin
                // ALU ctrls
                rsrc         = instr[3:0];
                rdest        = instr[11:8];
                op           = (instr[15:12] == 4'b0000) ? instr[7:4] : instr[15:12];
                imm8         = instr[7:0];
                imm_en       = (instr[15:12] == 4'b0000) ? 1'b0 : 1'b1;
                alu_mux_ctrl = 0;
                
                // Reg ctrls
                reg_en = 16'd0;
                reg_we = 0;
                
                // PC ctrls
                pc_en       = 0;
                pc_mux_ctrl = 0;
                disp        = 16'd0;
                
                // LOAD/STORE ctrls
                LS_ctrl = 0;
                ir_en   = 0;

                if (!paused) begin
                    // Normal execution & writeback
                    if (op != CMP && op != NOP) begin
                        reg_en = 16'd1 << rdest;
                        reg_we = 1;
                    end
                    pc_en = 1;
                end
            end
            
            S4: begin
                // ALU ctrls
                rsrc         = 0;
                rdest        = ir_reg[3:0];
                op           = 4'd0;
                imm8         = 8'd0;
                imm_en       = 0;
                alu_mux_ctrl = 0;
                
                // Reg ctrls
                reg_en = 16'd0;
                reg_we = 0;
                
                // PC ctrls
                pc_en       = 0;
                pc_mux_ctrl = 0;
                disp        = 16'd0;
                
                // LOAD/STORE ctrls
                LS_ctrl = 1;
                ir_en   = 0;
            end
            
            S5: begin
                // ALU ctrls
                rsrc         = 0;
                rdest        = 0;
                op           = 4'd0;
                imm8         = 8'd0;
                imm_en       = 0;
                alu_mux_ctrl = 1;
                
                // Reg ctrls
                reg_en = 16'd0;
                reg_we = 0;
                
                // PC ctrls
                pc_en       = 0;
                pc_mux_ctrl = 0;
                disp        = 16'd0;
                
                // LOAD/STORE ctrls
                LS_ctrl = 0;
                ir_en   = 0;

                if (!paused) begin
                    // Normal execution & writeback
                    if (op != CMP && op != NOP) begin
                        reg_en = 16'd1 << rdest;
                        reg_we = 1;
                    end
                    pc_en = 1;
                end
            end
        endcase
    end

endmodule