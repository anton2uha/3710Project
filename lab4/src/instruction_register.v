module instruction_register (
    input wire clk,
    input wire reset,
    input wire ir_en,
    input wire [15:0] DOUT,   // memory output
    output reg [15:0] ir_out  // latched instruction
);
    always @(posedge clk or posedge reset) begin
        if (reset)
            ir_out <= 16'b0;
        else if (ir_en)
            ir_out <= DOUT;
    end
endmodule
