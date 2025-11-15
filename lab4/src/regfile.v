`timescale 1ns / 1ps
module regfile #(
    parameter [15:0] INIT_R1 = 16'h0011,
    parameter [15:0] INIT_R2 = 16'h0022,
	 parameter [15:0] INIT_R3 = 16'h0033,
	 parameter [15:0] INIT_R4 = 16'h1111,
	 parameter [15:0] INIT_R5 = 16'h1112,
	 parameter [15:0] INIT_R6 = 16'heeee,
	 parameter [15:0] INIT_R7 = 16'h0001,
	 parameter [15:0] INIT_R8 = 16'h0001,
	 parameter [15:0] INIT_R10 = 16'h5555,
	 parameter [15:0] INIT_R11 = 16'h0015
)(
    input      	  clk,
    input         reset,
    input  [15:0] wdata,        // write data input, connected to ALU (eventually memory?)
    input  [15:0] regEnable,    // enables for each register
    input  [3:0]  raddrA,       // read address A, selects which register to output.
    input  [3:0]  raddrB,       // read address B
    output [15:0] rdataA,       // read data A
    output [15:0] rdataB        // read data B
);
	
	// 16 registers, each 16 bits wide
	reg [15:0] r [0:15];

	genvar i;
	
	generate
	for(i=0; i<=15;i=i+1) 
	begin:reg_write
		always @(posedge clk)
		begin
			if (reset == 1'b0) begin
				// if(i == 1) r[i] <= INIT_R1;
				// else if(i == 2) r[i] <= INIT_R2;
				// else if(i == 3) r[i] <= INIT_R3;
				// else if(i == 4) r[i] <= INIT_R4;
				// else if(i == 5) r[i] <= INIT_R5;
				// else if(i == 6) r[i] <= INIT_R6;
				// else if(i == 7) r[i] <= INIT_R7;
				// else if(i == 8) r[i] <= INIT_R8;
				// else if(i == 10) r[i] <= INIT_R10;
				// else if(i == 11) r[i] <= INIT_R11;
				// else r[i]<= 16'd0;
				r[i] <= 16'd0;
			end
			else
				if(regEnable[i]==1'b1)
				r[i] <= wdata;
		end
	end
	endgenerate

    assign rdataA = r[raddrA];
    assign rdataB = r[raddrB];

endmodule
