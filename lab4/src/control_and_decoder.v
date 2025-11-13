// Control and decoder FSM from instruction opcodes following the CR16a architecture
`timescale 1ns / 1ps

module control_and_decoder #(
    parameter [4:0] instrs = 5'd24 // number of instructions to execute before pausing
)(
    input  wire        clk,
    input  wire        reset,     
    input  wire [4:0]  flags,
    input  wire [15:0] instr,  
    input  wire [15:0] ir_reg,

    output reg         pc_en,
    output reg         mem_we,
    output reg         pc_mux_ctrl,
    output reg         LS_ctrl,
    output reg         ir_en,
    output reg         reg_we,
    output reg         imm_en,
    output reg         alu_mux_ctrl,
    output reg  [3:0]  op,
    output reg  [3:0]  rsrc,
    output reg  [3:0]  rdest,
    output reg  [7:0]  imm8,        
    output reg  [15:0] reg_en,
    output reg  [15:0] disp,
    output reg         pc_load
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
    reg branch_taken;

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
                    if (instr[15:12] == 4'b0100 && instr[7:4] == 4'b0100)
                        state <= S3; // STORE
                    else if (instr[15:12] == 4'b0100 && instr[7:4] == 4'b0000)
                        state <= S4; // LOAD
                    else
                        state <= S2;
                end
                
                S2: state <= (paused) ? S2 : S0;
                S3: state <= S0;
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
                pc_load     = 0;
                
                // LOAD/STORE ctrls
                LS_ctrl = 0;
                ir_en   = 0;
                
                // Memory write
                mem_we       = 0;
                branch_taken = 0;
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
                pc_load     = 0;
                
                // LOAD/STORE ctrls
                LS_ctrl = 0;
                ir_en   = 0;
                
                // Memory write
                mem_we = 0;

                if (instr[15:12] == 4'b0000) begin
                    op = instr[7:4];
                end else begin 
                    op     = instr[15:12];
                    imm_en = 1; 
                end
                
                // LOAD instruction
                if (instr[15:12] == 4'b0100 && instr[7:4] == 4'b0000) 
                    ir_en = 1;
                
                // JCOND instruction
                if (instr[15:12] == 4'b0100 && instr[7:4] == 4'b1100) 
                    rsrc = instr[3:0];
            end
            
            S2: begin
                // ALU ctrls
                rsrc         = instr[3:0];
                rdest        = instr[11:8];
                op           = (instr[15:12] == 4'b0000) ? instr[7:4] : instr[15:12];
                imm8         = instr[7:0];
                imm_en       = (instr[15:12] == 4'b0000) ? 1'b0 : 1'b1;
                alu_mux_ctrl = 0;
                
                $display("S2 instr=%h rdest=%d rsrc=%d", instr, instr[11:8], instr[3:0]);
                
                // Reg ctrls
                reg_en = 16'd0;
                reg_we = 0;
                
                // PC ctrls
                pc_en       = 0;
                pc_mux_ctrl = 0;
                disp        = 16'd0;
                pc_load     = 0;
                
                // LOAD/STORE ctrls
                LS_ctrl = 0;
                ir_en   = 0;
                
                // Memory write
                mem_we = 0;
                
                // Bcond disp (1100 cond disp)
                // Flags[4,3,2,1,0] = Zero(Z), Carry(C), Overflow(O), Low(L), Negative(N)
                if (instr[15:12] == 4'b1100) begin
                    case (instr[11:8])
                        4'b0000: branch_taken = (flags[4] == 1'b1);                    // EQ
                        4'b0001: branch_taken = (flags[4] == 1'b0);                    // NE
                        4'b1101: branch_taken = (flags[0] == 1'b1 || flags[4] == 1'b1);// GE
                        4'b0010: branch_taken = (flags[3] == 1'b1);                    // CS
                        4'b0011: branch_taken = (flags[3] == 1'b0);                    // CC
                        4'b0100: branch_taken = (flags[1] == 1'b1);                    // HI
                        4'b0101: branch_taken = (flags[1] == 1'b0);                    // LS
                        4'b1010: branch_taken = (flags[1] == 1'b0 && flags[4] == 1'b0);// LO
                        4'b1011: branch_taken = (flags[1] == 1'b1 && flags[4] == 1'b1);// HS
                        4'b0110: branch_taken = (flags[0] == 1'b1);                    // GT
                        4'b0111: branch_taken = (flags[0] == 1'b0);                    // LE
                        4'b1100: branch_taken = (flags[0] == 1'b0 && flags[4] == 1'b0);// LT
                        4'b1110: branch_taken = 1'b1;                                  // UC
                        4'b1111: branch_taken = 1'b0;                                  // NEVER JMP
                        default: branch_taken = 1'b0;
                    endcase
                    
                    if (branch_taken) begin
                        pc_mux_ctrl = 1'b1;
                        disp        = {{8{instr[7]}}, instr[7:0]};
                    end
                    
                    reg_en = 16'd0; 
                    reg_we = 1'b0;
                    
                    if (!paused) pc_en = 1'b1;
                end
                
                // Jcond Rtarget (0100 cond 1100 Rtarget)
                else if (instr[15:12] == 4'b0100 && instr[7:4] == 4'b1100) begin
                    // Flags[4,3,2,1,0] = Zero(Z), Carry(C), Overflow(O), Low(L), Negative(N)
                    case (instr[11:8])
                        4'b0000: branch_taken = (flags[4] == 1'b1);                    // EQ
                        4'b0001: branch_taken = (flags[4] == 1'b0);                    // NE
                        4'b1101: branch_taken = (flags[0] == 1'b1 || flags[4] == 1'b1);// GE
                        4'b0010: branch_taken = (flags[3] == 1'b1);                    // CS
                        4'b0011: branch_taken = (flags[3] == 1'b0);                    // CC
                        4'b0100: branch_taken = (flags[1] == 1'b1);                    // HI
                        4'b0101: branch_taken = (flags[1] == 1'b0);                    // LS
                        4'b1010: branch_taken = (flags[1] == 1'b0 && flags[4] == 1'b0);// LO
                        4'b1011: branch_taken = (flags[1] == 1'b1 && flags[4] == 1'b1);// HS
                        4'b0110: branch_taken = (flags[0] == 1'b1);                    // GT
                        4'b0111: branch_taken = (flags[0] == 1'b0);                    // LE
                        4'b1100: branch_taken = (flags[0] == 1'b0 && flags[4] == 1'b0);// LT
                        4'b1110: branch_taken = 1'b1;                                  // UC
                        4'b1111: branch_taken = 1'b0;                                  // NEVER JMP
                        default: branch_taken = 1'b0;
                    endcase
                    
                    if (branch_taken) begin
                        pc_load = 1'b1;
                        if (!paused) pc_en = 1'b1;
                    end else begin
                        pc_load = 1'b0;
                        if (!paused) pc_en = 1'b1; 
                    end
                    
                    reg_en = 16'd0; 
                    reg_we = 1'b0;
                end
                
                else begin
                    if (!paused) begin
                        // Normal execution & writeback
                        if (op != CMP && op != NOP) begin
                            reg_en = 16'd1 << rdest;
                            reg_we = 1;
                        end
                        pc_en = 1;
                    end
                end
            end
            
            S3: begin
                // ALU controls
                rsrc         = instr[3:0]; 
                rdest        = instr[11:8];  
                op           = 4'd0;
                imm8         = 8'd0;
                imm_en       = 0;
                alu_mux_ctrl = 0;

                // Regfile write off
                reg_en = 16'd0;
                reg_we = 0;

                // PC control
                pc_en       = 1; 
                pc_mux_ctrl = 0;
                disp        = 16'd0;
                pc_load     = 0;

                // LS / IR control
                LS_ctrl = 1;
                ir_en   = 0;

                // Memory write
                mem_we = 1;
            end
            
            S4: begin
                // ALU ctrls
                rsrc         = ir_reg[3:0];
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
                pc_load     = 0;
                
                // LOAD/STORE ctrls
                LS_ctrl = 1;
                ir_en   = 0;
                
                // Memory write
                mem_we = 0;
            end
            
            S5: begin
                // ALU ctrls
                rsrc         = 0;
                rdest        = ir_reg[11:8];
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
                pc_load     = 0;
                
                // LOAD/STORE ctrls
                LS_ctrl = 0;
                ir_en   = 0;
                
                // Memory write
                mem_we = 0;

                // Writeback
                reg_en = 16'd1 << rdest;
                reg_we = 1;
                pc_en  = 1;
            end
        endcase
    end

endmodule