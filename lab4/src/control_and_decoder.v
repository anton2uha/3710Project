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
module control_and_decoder(
    input  wire        clk,
    input  wire        reset,     
    input  wire [15:0] instr,        

    input  wire        Z, L, N, C, F,

    output reg         pc_en,        // to do PC+1 
    output reg         ir_en,        // IR <= DOUT during S1
    output reg         reg_we,       // regfile write enable
    output reg         imm_en,       // 0: B=Rdest (RR), 1: B=Imm 
    output reg  [3:0]  op,           // opcode (mapped from instr[12:9])
    output reg  [3:0]  rsrc,         // src reg index  (instr[4:1])
    output reg  [3:0]  rdest,        // dest reg index (instr[8:5])
    output reg  [7:0]  imm8,        
    output reg  [15:0] reg_en,
);
    
    // states
    // Should we set pc_en to 1 in S0, or the states before S0?
    parameter S0 = 3'd0; // fetch stage
    parameter S1 = 3'd1; // decode stage
    parameter S2 = 3'd2; // r-type: exectution + writeback | next state -> S0
    parameter S3 = 3'd3; // store: writeback into mem for store | next state -> S0
    parameter S4 = 3'd4; // load: apply load address to memory | next state -> S5
    parameter S5 = 3'd5; // load: writeback from mem to regfile | next state -> S0

    reg [4:0] state, next_state, prev_state;

    integer i = 0;
    parameter instrs = 1;


    //this loop takes care of state
    always @(posedge clk or negedge reset) begin
        if(!reset_n) begin
            state <= S0;
        end
        else begin 
            case (state)
                S0: state <= S1;
                S1: state <= S2;
                S2: begin
                    if(i == insts) state <= S2;
                    else state <= S0;
                end
                default: state <= S0;   // safety
            endcase
        end
    end

    //this loop executes logic for current state
    always @(*) begin
        case (state)
            S0: begin
                pc_en = 1;
                ir_en = 0;
                reg_we = 0;
                imm_en = 0;
                rsrc = 0;
                rdest = 0;
                op = 4'd0;
                reg_en = 16'd0;
                imm8   = 8'd0; 
                // TODO: Fetch stage, what needs to happen in here?
                pc_en = 0;
            end
            S1: begin
                pc_en = 0;
                reg_we = 0;
                imm_en = 0;
                reg_en = 16'd0;

                // opcode = instr[15:12];
                // rd     = instr[11:8];
                // ext    = instr[7:4];
                // rs     = instr[3:0];
                imm8   = instr[7:0];
                rdest  = instr[11:8];
                rsrc   = instr[3:0];

                // IR cntl
                ir_en = 1;

                if(instr[15:12] != 4'b0000) begin
                    op = instr[15:12];
                end
                else begin 
                    op = instr[7:4];
                    // set imm cntl
                    imm_en = 1; 
                end
            end
            S2: begin
                imm_en = 0;
                reg_en = 16'd0;
                imm8   = instr[7:0];
                rdest  = instr[11:8];
                rsrc   = instr[3:0];

                if(instr[15:12] == 4'b0000) begin
                    op = instr[7:4];
                end
                else begin 
                    op = instr[15:12];
                    // set imm cntl
                    imm_en = 1; 
                end
                

                // IR cntl
                ir_en = 1;

                // reg_we & reg_en
                // Convert rd into a 16 bit value for reg_en. Ex: if rd is 4 then reg_en would be 0000000000010000
                reg_en = 16'd1 << rdest;
                reg_we = 1;

                // pc
                pc_en = 1;
            end
        endcase
    end

endmodule
