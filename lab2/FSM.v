`timescale 1ns/1ps
module FSM (input clk, input reset, output [15:0] out);

reg [3:0] opcode, rdest, rsrc;
reg [15:0] regEnable, wdata, immediate;
reg regFileWriteEnable, useImmediate;

initial begin
    immediate = 0;
    useImmediate = 0;
    opcode = 0;
    rdest  = 0;
    rsrc   = 0;
    wdata  = 0;
    regEnable = 0;
    regFileWriteEnable = 0;
end


Regfile_ALU_Datapath my_dataPath
(
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


parameter S0 = 5'd0;
parameter S1 = 5'd1;
parameter S2 = 5'd2;
parameter S3 = 5'd3;
parameter S4 = 5'd4;
parameter S5 = 5'd5;
parameter S6 = 5'd6;
parameter S7 = 5'd7;
parameter S8 = 5'd8;
parameter S9 = 5'd9;
parameter S10 = 5'd10;
parameter S11 = 5'd11;
parameter S12 = 5'd12;
parameter S13 = 5'd13;
parameter S14 = 5'd14;
parameter S15 = 5'd15;
parameter S16 = 5'd16;

// Defining start values as parameters so we can change them and test diff fib sequences
parameter [15:0] F0_INIT = 16'd1;
parameter [15:0] F1_INIT = 16'd2;

reg [4:0] state;
//this loop takes care of state
always @(posedge clk or negedge reset) begin
    if (!reset)
        state <= S0;       // start in S0 after reset
    else begin
        case (state)
				S0: state <= S1;
				S1: state <= S2;
				S2: state <= S3;
				S3: state <= S4;
				S4: state <= S5;
				S5: state <= S6;
				S6: state <= S7;
				S7: state <= S8;
				S8: state <= S9;
				S9: state <= S10;
				S10: state <= S11;
				S11: state <= S12;
				S12: state <= S13;
				S13: state <= S14;
				S14: state <= S15;
				S15: state <= S15;
				default: state <= S0;   // safety
        endcase
    end
end


//this loop executes logic for current state.
always @(*) begin
	case (state)
		S0: begin //fill r[0]
			wdata = F0_INIT;
			opcode = 4'b0101;
			rdest = 4'd0;
			rsrc = 4'd1;
			regFileWriteEnable = 1;
			regEnable = 16'b0000000000000001;
		end
		
		S1: begin //fill r[1]
			wdata = F1_INIT;
			opcode = 4'b0101;
			rdest = 4'd0;
			rsrc = 4'd1;
			regFileWriteEnable = 1;
			regEnable = 16'b0000000000000010;
		end
		
		S2: begin //r[2] = r[0] + r[1] => r[2] = 0 + 1 = 1
			wdata = 16'b0;
			opcode = 4'b0101;
			rdest = 4'd0;
			rsrc = 4'd1;
			regFileWriteEnable = 0;
			regEnable = 16'b0000000000000100;
		end
		
		S3: begin //r[3] = r[1] + r[2] => r[3] = 1 + 1 = 2
			wdata = 16'b0;
			opcode = 4'b0101;
			rdest = 4'd1;
			rsrc = 4'd2;
			regFileWriteEnable = 0;
			regEnable = 16'b0000000000001000;
		end
		
		S4: begin //r[4] = r[2] + r[3] => r[4] = 1 + 2 = 3
			wdata = 16'b0;
			opcode = 4'b0101;
			rdest = 4'd2;
			rsrc = 4'd3;
			regFileWriteEnable = 0;
			regEnable = 16'b0000000000010000;
		
		end
		
		S5: begin //r[5] = r[3] + r[4] => r[5] = 2 + 3 = 5
			wdata = 16'b0;
			opcode = 4'b0101;
			rdest = 4'd3;
			rsrc = 4'd4;
			regFileWriteEnable = 0;
			regEnable = 16'b0000000000100000;
		
		end
		
		S6: begin //r[6] = r[4] + r[5] => r[6] = 3 + 5 = 8
			wdata = 16'b0;
			opcode = 4'b0101;
			rdest = 4'd4;
			rsrc = 4'd5;
			regFileWriteEnable = 0;
			regEnable = 16'b0000000001000000;
		
		end
		
		S7: begin //r[7] = r[5] + r[6] => r[7] = 5 + 8 = 13
			wdata = 16'b0;
			opcode = 4'b0101;
			rdest = 4'd5;
			rsrc = 4'd6;
			regFileWriteEnable = 0;
			regEnable = 16'b0000000010000000;
		
		end
		
		S8: begin //r[8] = r[6] + r[7] => r[8] = 8 + 13 = 21
			wdata = 16'b0;
			opcode = 4'b0101;
			rdest = 4'd6;
			rsrc = 4'd7;
			regFileWriteEnable = 0;
			regEnable = 16'b0000000100000000;
		
		end
	
		S9: begin //r[9] = r[7] + r[8] => r[9] = 13 + 21 = 34
			wdata = 16'b0;
			opcode = 4'b0101;
			rdest = 4'd7;
			rsrc = 4'd8;
			regFileWriteEnable = 0;
			regEnable = 16'b0000001000000000;
		
		end
		
		S10: begin //r[10] = r[8] + r[9] => r[10] = 21 + 34 = 55
			wdata = 16'b0;
			opcode = 4'b0101;
			rdest = 4'd8;
			rsrc = 4'd9;
			regFileWriteEnable = 0;
			regEnable = 16'b0000010000000000;
		
		end
		
		S11: begin //r[11] = r[9] + r[10] => r[11] = 34 + 55 = 89
			wdata = 16'b0; 
			opcode = 4'b0101;
			rdest = 4'd9;
			rsrc = 4'd10;
			regFileWriteEnable = 0;
			regEnable = 16'b0000100000000000;
		
		end
		
		S12: begin //r[12] = r[10] + r[11] => r[12] = 55 + 89 = 144
			wdata = 16'b0;
			opcode = 4'b0101;
			rdest = 4'd10;
			rsrc = 4'd11;
			regFileWriteEnable = 0;
			regEnable = 16'b0001000000000000;
		
		end
	
		S13: begin //r[13] = r[11] + r[12] => r[13] =  89 + 144 = 233
			wdata = 16'b0;
			opcode = 4'b0101;
			rdest = 4'd11;
			rsrc = 4'd12;
			regFileWriteEnable = 0;
			regEnable = 16'b0010000000000000;
		
		end
		
		S14: begin //r[14] = r[12] + r[13] => r[14] = 144 + 233 = 377
			wdata = 16'b0;
			opcode = 4'b0101;
			rdest = 4'd12;
			rsrc = 4'd13;
			regFileWriteEnable = 0;
			regEnable = 16'b0100000000000000;
		end
		
		S15: begin //r[15] = r[13] + r[14] => r[15] = 233 + 377 = 610
			wdata = 16'b0;
			opcode = 4'b0101;
			rdest = 4'd13;
			rsrc = 4'd14;
			regFileWriteEnable = 0;
			regEnable = 16'b1000000000000000;
		end
		
		default: begin
			wdata = 16'b0;
			opcode = 4'b0101;
			rdest = 4'd0;
			rsrc = 4'd11;
			regFileWriteEnable = 0;
			regEnable = 16'b0000000000000000;
		end
	
	endcase


end


endmodule