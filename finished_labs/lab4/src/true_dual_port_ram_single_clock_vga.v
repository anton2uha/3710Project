// Quartus Prime Verilog Template
// True Dual Port RAM with single clock
`timescale 1ns / 1ps
module true_dual_port_ram_single_clock_vga
#(parameter DATA_WIDTH=16, parameter ADDR_WIDTH=16)
(
	input [(DATA_WIDTH-1):0] data_a, data_b,
	input [(ADDR_WIDTH-1):0] addr_a, addr_b,
	input we_a, we_b, clk,
	output reg [(DATA_WIDTH-1):0] q_a, q_b
);

	// Declare the RAM variable
	reg [DATA_WIDTH-1:0] ram[2**ADDR_WIDTH-1:0];

	// load memory using $readmemh
	initial begin
        $readmemh("C:/Users/toaoi/Documents/Repos/school/ECE3710/3710Project/game_code/Combined_manWalking+Cactus.hex", ram);
	end

	// Port A 
	always @ (posedge clk)
	begin
		if (we_a) 
		begin
			ram[addr_a] <= data_a;
			q_a <= data_a;
		end
		else 
		begin
			q_a <= ram[addr_a];
		end 
	end 

	// Port B 
	always @ (posedge clk)
	begin
		// Port A takes write precendence. Therefore, if A is write enabled 
		// and has the same writing address as Port B, then just dont write to port B
		if (we_b && !(we_a && addr_a == addr_b)) 
		begin
			ram[addr_b] <= data_b;
			q_b <= data_b;
		end
		else 
		begin
			q_b <= ram[addr_b];
		end 
	end

endmodule