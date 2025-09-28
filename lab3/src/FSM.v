/*
    Design choices for FPGA:
        - initialize using $readmemh() to load memory in the memory module
        - Display data from one memory address (Right now address 512 in S9)

*/

`timescale 1ns/1ps

module FSM (input clk, reset, output [(DATA_WIDTH-1):0] q_a, q_b);

    parameter DATA_WIDTH = 16;
	 parameter ADDR_WIDTH = 16;
    reg [(DATA_WIDTH-1):0] memory [6:0]; // used to store read values and hold our modifications for state S4

    reg [(DATA_WIDTH-1):0] data_a, data_b;
    reg [(ADDR_WIDTH-1):0] addr_a, addr_b;
    reg we_a, we_b;


    true_dual_port_ram_single_clock my_ram
    (
        .data_a(data_a),
        .data_b(data_b),
        .addr_a(addr_a),
        .addr_b(addr_b),
        .we_a(we_a),
        .we_b(we_b),
        .clk(clk),
        .q_a(q_a),
        .q_b(q_b)
    );

    parameter S0 = 5'd0; // Read 0, 1
    parameter S1 = 5'd1; // Read 2
    parameter S2 = 5'd2; // Read 510, 511
    parameter S3 = 5'd3; // Read 512, 513
    parameter S4 = 5'd4; // Modify 0-3 & 510-513
    parameter S5 = 5'd5; // Write 0, 1
    parameter S6 = 5'd6; // Write 2, 3
    parameter S7 = 5'd7; // Write 510, 511
    parameter S8 = 5'd8; // Write 512, 513
    parameter S9 = 5'd9; // Read 512

    reg [4:0] state, next_state;


    //this loop takes care of state
    always @(posedge clk or negedge reset) begin
        if (!reset) state <= S0;
        else state <= next_state;
    end


    //this loop executes logic for current state.
    always @(*) begin
        // Initialize all values to prevent latches
        data_a = 0;
        data_b = 0;
        addr_a = 0;
        addr_b = 0;
        we_a = 0;
        we_b = 0;
        next_state = state;

        case (state)
            S0: begin // read at 0 & 1
                addr_a = 0;
                addr_b = 1;
                next_state = S1;  
            end
            
            S1: begin // read at 2
                addr_a = 2;
                next_state = S2;
            end
            
            S2: begin // read at 510 & 511
                addr_a = 510;
                addr_b = 511;
                next_state = S3;
            end
            
            S3: begin // read at 512 & 513
                addr_a = 512;
                addr_b = 513;
                next_state = S4;
            end

            S4: begin // modify values
                next_state = S5;
            end

            S5: begin // write at 0 & 1
                addr_a = 0;
                addr_b = 1;
                data_a = memory[0];
                data_b = memory[1];
                we_a = 1;
                we_b = 1;    
                next_state = S6;
            end

            S6: begin // write at 2
                addr_a = 2;
                data_a = memory[2];
                we_a = 1;
                next_state = S7; 
            end

            S7: begin // write at 510 & 511
                addr_a = 510;
                addr_b = 511;
                data_a = memory[3];
                data_b = memory[4];
                we_a = 1;
                we_b = 1;  
                next_state = S8;  
            end

            S8: begin // write at 512 & 513
                addr_a = 512;
                addr_b = 513;
                data_a = memory[5];
                data_b = memory[6];
                we_a = 1;
                we_b = 1;    
                next_state = S9;
            end

            S9: begin // read at 512
                addr_a = 512;
					 addr_b = 512;
                next_state = S9; // stay here
            end
            default: begin
                // default values already set at start of always block
            end
        endcase
    end
    
    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            memory[0] <= 0; 
            memory[1] <= 0; 
            memory[2] <= 0;
            memory[3] <= 0; 
            memory[4] <= 0; 
            memory[5] <= 0;
            memory[6] <= 0;
        end 
        else begin
            case (state)
                S0: begin
                    memory[0] <= q_a;
                    memory[1] <= q_b; 
                end
                S1: begin
                    memory[2] <= q_a;
                end
                S2: begin
                    memory[3] <= q_a;
                    memory[4] <= q_b;
                end
                S3: begin
                    memory[5] <= q_a;
                    memory[6] <= q_b;
                end
                S4: begin
                    memory[0] <= memory[0] + 16'd5;
                    memory[1] <= memory[1] + 16'd5;
                    memory[2] <= memory[2] + 16'd5;
                    memory[3] <= memory[3] + 16'd5;
                    memory[4] <= memory[4] + 16'd5;
                    memory[5] <= memory[5] + 16'd5;
                    memory[6] <= memory[6] + 16'd5;
                end
                S9: ;
                default: ;
            endcase
        end
    end
endmodule