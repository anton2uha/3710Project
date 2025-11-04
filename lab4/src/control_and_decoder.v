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

    wire [3:0] opcode;
    wire [3:0] rd;
    wire [3:0] ext;
    wire [3:0] rs;
    
    // states
    // Should we set pc_en to 1 in S0, or the states before S0?
    parameter S0 = 3'd0; // fetch stage
    parameter S1 = 3'd1; // decode stage
    parameter S2 = 3'd2; // r-type: exectution + writeback | next state -> S0
    parameter S3 = 3'd3; // store: writeback into mem for store | next state -> S0
    parameter S4 = 3'd4; // load: apply load address to memory | next state -> S5
    parameter S5 = 3'd5; // load: writeback from mem to regfile | next state -> S0

    reg [4:0] state, next_state, prev_state;

    //this loop takes care of state
    always @(posedge clk or negedge reset) begin
        // if (!reset) begin
        //     state      <= S0;
        //     prev_state <= S0; // initialize previous state on reset for clean capture
        // end
        // else begin
        //     prev_state <= state;
        //     state      <= next_state;
        // end
        case (state)
            S0: state <= S1;
            S1: state <= S2;
            S2: state <= S3;
            S3: state <= S0;
            default: state <= S0;   // safety
        endcase
    end

    //this loop executes logic for current state
    always @(*) begin
        // Initialize all values to prevent latches
        opcode = instr[15:12];
        rd     = instr[11:8];
        ext    = instr[7:4];
        rs     = instr[3:0];
        case (state)
            S0: begin
                // TODO: Fetch stage, what needs to happen in here?
            end
            S1: begin
            
            end
            S2: begin

            end
            S3: begin

            end
        endcase
    end

endmodule
