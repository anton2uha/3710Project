`timescale 1ns / 1ps

module program_counter(
	input en, clk, rst_n, pc_mux,
	input [15:0] disp,
	input pc_load,
	input [15:0] tgt_addr,
	output reg [15:0] pc
);
	
	wire [15:0] x;
	
	//mux
	assign x = (pc_mux == 0) ? 16'd1 : disp;

	always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        pc <= 16'd0;
    end
    else if (en) begin
       /*$display("Time=%0t PC Module: en=1, pc_load=%b, pc_mux=%b, disp=%h, x=%h, tgt_addr=%h, pc=%h", 
                 $time, pc_load, pc_mux, disp, x, tgt_addr, pc);*/
        if(pc_load) begin
            pc <= tgt_addr;
        end else begin
            pc <= pc + x;
        end
    end
end

endmodule 