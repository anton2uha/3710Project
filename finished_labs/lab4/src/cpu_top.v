`timescale 1ns / 1ps
module cpu_top (
	input clk,
	input reset,
	inout  wire PS2_CLK,    
    inout  wire PS2_DAT,
    output wire VGA_HS,
    output wire VGA_VS,
    output wire VGA_CLK,
    output wire VGA_BLANK_N,
    output wire VGA_SYNC_N,
    output wire [7:0] VGA_R,
    output wire [7:0] VGA_G,
    output wire [7:0] VGA_B,
	output [15:0] out // output of the ALU to show on 7 seg on fpga.
);

//enable and control wires (from control FSM)
wire pc_en, mem_we, pc_mux_crtl, LS_ctrl, ir_en, reg_we, imm_en, alu_mux_ctrl;
wire [15:0] reg_en;
wire [15:0] disp;

//IR reg
wire[15:0] ir_reg;

//instruction info (from control FSM)
wire [3:0] op, rsrc, rdest;
wire [15:0] imm;

//memory port wires
wire [15:0] data_a, addr_a, q_a;
wire we_a;

wire [15:0] data_b, addr_b, q_b;
wire we_b;
wire [15:0] vga_addr_b;
wire vga_we_b;

wire LSctrl;
wire [15:0] mem_addr_a; //output of LSctrl mux

// wires for jump
wire pc_load;
wire [15:0] tgt_addr;

//program counter
wire [15:0] pc;

//regFile connections
wire [15:0] rdataA; //output A from regfile
wire [15:0] rdataB; //output B from regfile
wire [15:0] regFileInput;

//ALU connections
wire [15:0] dataB; //wire from imm mux to port B of ALU
wire [15:0] aluOut;
reg [4:0] flags_reg;   // Stored flags
wire [4:0] flags_next; // New flags from ALU

wire space_is_down;
wire space_pressed_pulse;

assign data_a = rdataA;
assign we_a = mem_we;
assign tgt_addr = rdataB;
assign data_b = 16'd0; // VGA uses port B read-only
assign addr_b = vga_addr_b;
assign we_b   = vga_we_b;

// Add a flag register with clock and reset
always @(posedge clk or negedge reset) begin
    if (!reset)
        flags_reg <= 5'b0;
    else if (pc_en)  // Update flags when instruction completes
        flags_reg <= flags_next;
end

/* //DEBUG PRINT
always @(posedge clk) begin
    if (pc_en) begin  // When instruction completes
        $display("Time=%0t S2: op=%b, rdest=%d, rsrc=%d, rdataA=%h, rdataB=%h", 
                 $time, op, rdest, rsrc, rdataA, rdataB);
    end
end */

// Port A: CPU. Port B: VGA (read-only fetches).
true_dual_port_ram_single_clock my_ram
(
	.data_a(data_a),
	.data_b(data_b),
	.addr_a(mem_addr_a),
	.addr_b(addr_b),
	.we_a(we_a),
	.we_b(we_b),
	.clk(clk),
	.q_a(q_a),
	.q_b(q_b)
);

program_counter my_pc(
	.en(pc_en), 
	.clk(clk), 
	.rst_n(reset),
	.pc_mux(pc_mux_ctrl),
	.disp(disp),
	.tgt_addr(tgt_addr), //[15:0]
	.pc_load(pc_load),
	.pc(pc) //[15:0]
);

control_and_decoder my_control_decode(
	.clk(clk), //inputs
	.reset(reset),     
	.instr(q_a),        
	.flags(flags_reg), // is this flags or flags_reg?
	.ir_reg(ir_reg),
	
	.pc_en(pc_en),	//outputs
	.pc_mux_ctrl(pc_mux_ctrl),
	.ir_en(ir_en),
	.reg_we(reg_we), //CHECK: not needed? just set reg_en = 0
	.imm_en(imm_en),
	.op(op),
	.rsrc(rsrc),
	.rdest(rdest),
	.imm(imm),        
   .reg_en(reg_en),
	.disp(disp),
	.LS_ctrl(LS_ctrl),
	.mem_we(mem_we),
	
	.alu_mux_ctrl(alu_mux_ctrl), //added	
	.pc_load(pc_load)
);

instruction_register my_ir
(
	.clk(clk),
	.reset(reset),
	.ir_en(ir_en),
	.DOUT(q_a),
	.ir_out(ir_reg)
);

// Load/Store ctrl mux
twoToOneMux LSmux 
(
	.a(pc),
	.b(rdataB),
	.sel(LS_ctrl),
	.y(mem_addr_a)
);

// A or B for register input? A because A = dest
twoToOneMux immMux 
(
	.a(rdataB),
	.b(imm), //CHECK: signed or zero extend?
	.sel(imm_en),
	.y(dataB)
);

twoToOneMux regFileInputMux 
(
	.a(aluOut),
	.b(q_a), //CHECK: is this same as Data_from_mem in diagram?
	.sel(alu_mux_ctrl),
	.y(regFileInput)
);

regfile my_regs
(
	.clk(clk),
	.reset(reset),
	.wdata(regFileInput),
	.regEnable(reg_en),
	.raddrA(rdest),
	.raddrB(rsrc),
	.space_is_down(space_is_down),
	.rdataA(rdataA),
	.rdataB(rdataB)
);

alu my_alu 
(
	.A(rdataA), 
	.B(dataB), 
	.C(aluOut), 
	.Opcode(op), 
	.cin(flags_reg[3]),
	.Flags(flags_next)
);

space_key_detector my_space (
    .CLOCK_50          (clk),
    .n_reset           (reset),
    .PS2_CLK           (PS2_CLK),
    .PS2_DAT           (PS2_DAT),
    .space_pressed_pulse(space_pressed_pulse), 
    .space_is_down     (space_is_down)
);

vga_corrected_top my_vga (
    .sys_clk(clk),
    .jump_btn(space_pressed_pulse),
    .ram_addr_b(vga_addr_b),
    .ram_we_b(vga_we_b),
    .ram_q_b(q_b),
    .VGA_HS(VGA_HS),
    .VGA_VS(VGA_VS),
    .VGA_CLK(VGA_CLK),
    .VGA_BLANK_N(VGA_BLANK_N),
    .VGA_SYNC_N(VGA_SYNC_N),
    .VGA_R(VGA_R),
    .VGA_G(VGA_G),
    .VGA_B(VGA_B)
);
	
assign out = aluOut;

endmodule
