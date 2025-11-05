`timescale 1ns / 1ps
// module program_counter(
// 	input en, clk, rst_n,
// 	input  [1:0]      pc_src,      // 00: +1, 01: PC + offset, 10: direct target, 11: alu result
//     input  [15:0]     offset,
//     input  [15:0]     direct_addr, // target address
//     input  [15:0]     alu_result,  // for jump-register or load/store computed next PC
// 	output reg [15:0] pc
// );

// 	wire [15:0] pc_plus1;
//     wire [15:0] pc_plus_offset;
//     wire [15:0] next_pc;

// 	assign pc_plus1 = pc + 16'd1;
// 	assign pc_plus_offset = pc + offset; //signed offset

// 	// selecting next PC source
//     assign next_pc = (pc_src == 2'b00) ? pc_plus1 :
//                      (pc_src == 2'b01) ? pc_plus_offset :
//                      (pc_src == 2'b10) ? direct_addr :
//                                          alu_result;

// 	always @(posedge clk or negedge rst_n) begin
// 		if(!rst_n) begin
// 			pc <= 16'h0000;
// 		end
// 		else if (en) begin
// 			pc <= next_pc;
// 		end
// 	end

// endmodule

module program_counter(
	input en, clk, rst_n,
	output reg [15:0] pc
);

	always @(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			pc <= 0;
		end
		else if (en) begin
			pc <= pc + 1;
		end
	end

endmodule