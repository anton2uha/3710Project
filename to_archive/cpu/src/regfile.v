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
    input  [3:0]  raddrB,	     // read address B
	input		  space_is_down,
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
				r[i] <= 16'd0;
			end
			else begin
				if(i == 13) begin
					r[i] <= {15'b0, space_is_down};
				end else if(regEnable[i]==1'b1) begin
					r[i] <= wdata;
				end
			end
		end
	end
	endgenerate

    assign rdataA = r[raddrA];
    assign rdataB = r[raddrB];

endmodule
