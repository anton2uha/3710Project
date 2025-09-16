
module regfile(
    input      	  clk,
<<<<<<< HEAD:regfile.v
    input      	  reset,
=======
    input         reset,
>>>>>>> 4c016b1068d454ee2d0bd8b49e32e5856dc1de16:lab2/regfile.v
    input  [15:0] wdata,        // write data input, connected to ALU (eventually memory?)
    input  [15:0] regEnable,    // enables for each register
    input  [3:0]  raddrA,       // read address A, selects which register to output.
    input  [3:0]  raddrB,       // read address B
    output [15:0] rdataA,      // read data A
    output [15:0] rdataB       // read data B
);
	
	// 16 registers, each 16 bits wide
	reg [15:0] r [0:15];

	genvar i;
	
	generate
	for(i=0; i<=15;i=i+1) 
	begin:reg_write
		always @(posedge clk)
		begin
			if (reset == 1'b0)
				r[i]<= 16'd0;
			else
				if(regEnable[i]==1'b1)
				r[i] <= wdata;
		end
	end
	endgenerate

    assign rdataA = r[raddrA];
    assign rdataB = r[raddrB];

endmodule
