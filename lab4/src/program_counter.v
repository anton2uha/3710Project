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