// Reworked VGA top that uses an external memory (single port) instead of an internal ROM.
// Simplified per user: only two position words are pulled from RAM during vertical blank:
//   word 0 @ POS_BASE      -> cactus X coordinate
//   word 1 @ POS_BASE + 1  -> man    Y coordinate
// Man X and cactus Y are fixed parameters.
// After positions are loaded, the same RAM port is reused for sprite pixel fetches.
`timescale 1ns / 1ps
module ian_rework_vga_top #(
    parameter integer ADDR_WIDTH      = 16,
    parameter [ADDR_WIDTH-1:0] POS_BASE   = 16'h8000, // base address for position words
    parameter [ADDR_WIDTH-1:0] SPR0_BASE  = 13'd0,    // base address for man pixels
    parameter [ADDR_WIDTH-1:0] SPR1_BASE  = 13'd4096, // base address for cactus pixels
    parameter integer SPRITE_WIDTH  = 32,
    parameter integer SPRITE_HEIGHT = 32,
    parameter integer SPRITE_SCALE  = 3,
    parameter [9:0]   MAN_X_FIXED      = 10'd0,     // man X stays fixed
    parameter [9:0]   CACTUS_Y_FIXED   = 10'd100    // cactus Y stays fixed
)(
    input  wire                  sys_clk,   // 50 MHz
    input  wire                  reset,
    // External memory interface (hook to cpu_top RAM port B)
    output reg  [ADDR_WIDTH-1:0] ram_addr_b,
    output wire                  ram_we_b,
    input  wire [15:0]           ram_q_b,
    // VGA pins
    output wire                  VGA_HS,
    output wire                  VGA_VS,
    output wire                  VGA_CLK,
    output wire                  VGA_BLANK_N,
    output wire                  VGA_SYNC_N,
    output wire [7:0]            VGA_R,
    output wire [7:0]            VGA_G,
    output wire [7:0]            VGA_B
);
    localparam [7:0] BG_R = 8'h88, BG_G = 8'hCC, BG_B = 8'h88;

    wire bright;
    wire pix_clk;
    wire [9:0] hcount, vcount;

    vga_control vc (
        .clk(sys_clk),
        .hsync(VGA_HS),
        .vsync(VGA_VS),
        .bright(bright),
        .pix_clk_out(pix_clk),
        .hcount(hcount),
        .vcount(vcount)
    );

    assign VGA_CLK     = pix_clk;
    assign VGA_BLANK_N = bright;
    assign VGA_SYNC_N  = 1'b0;

    // External RAM is read-only here
    assign ram_we_b   = 1'b0;

    // Cached positions (loaded from RAM during vblank)
    reg [15:0] cactus_x_reg;
    reg [15:0] man_y_reg;

    // Simple loader to pull two words during vertical blank.
    // Uses one-cycle issue, one-cycle capture; ram_addr_b is driven here while loading.
    reg loading;
    reg [1:0] load_phase; // 0=idle, 1=issue addr, 2=capture
    reg [1:0] load_index; // 0=cactus_x, 1=man_y

    // Next-state signals for loader FSM
    reg loading_next;
    reg [1:0] load_phase_next;
    reg [1:0] load_index_next;
    reg [15:0] cactus_x_next;
    reg [15:0] man_y_next;

    wire vblank_start = (hcount == 10'd0) && (vcount == 10'd480); // start of vertical blank for 640x480

    // Combinational block: compute next state for loader FSM
    always @(*) begin
        // Default: hold current values
        loading_next    = loading;
        load_phase_next = load_phase;
        load_index_next = load_index;
        cactus_x_next   = cactus_x_reg;
        man_y_next      = man_y_reg;

        if (vblank_start) begin
            // Kick off the two-word burst at vblank start
            loading_next    = 1'b1;
            load_phase_next = 2'd1; // issue first address
            load_index_next = 2'd0;
        end else if (loading) begin
            case (load_phase)
                2'd1: begin
                    // Issue address for current word (RAM drive happens in address block)
                    load_phase_next = 2'd2; // next cycle will capture
                end
                2'd2: begin
                    // Capture returned data from RAM after one-cycle latency
                    if (load_index == 2'd0)
                        cactus_x_next = ram_q_b[9:0];
                    else
                        man_y_next = ram_q_b[9:0];
                    // Move to next word or finish
                    if (load_index == 2'd1) begin
                        loading_next    = 1'b0; // done with both words
                        load_phase_next = 2'd0;
                    end else begin
                        load_index_next = load_index + 1'b1;
                        load_phase_next = 2'd1; // issue next address
                    end
                end
                default: begin
                    load_phase_next = 2'd0;
                end
            endcase
        end
    end

    // Sequential block: register next state on clock edge
    always @(posedge pix_clk) begin
        if (reset) begin
            loading      <= 1'b0;
            load_phase   <= 2'd0;
            load_index   <= 2'd0;
            cactus_x_reg <= 16'd0;
            man_y_reg    <= 16'd0;
        end else begin
            loading      <= loading_next;
            load_phase   <= load_phase_next;
            load_index   <= load_index_next;
            cactus_x_reg <= cactus_x_next;
            man_y_reg    <= man_y_next;
        end
    end

    // Sprite helpers
    wire man_hit;
    wire [ADDR_WIDTH-1:0] man_req_addr;
    wire [7:0] man_r, man_g, man_b;
    wire man_opaque;

    wire cactus_hit;
    wire [ADDR_WIDTH-1:0] cactus_req_addr;
    wire [7:0] cactus_r, cactus_g, cactus_b;
    wire cactus_opaque;

    // Selection for returned RAM data (one sprite per pixel)
    reg [1:0] sel_q;   // registered selection (previous cycle)
    reg [1:0] sel_next;
    localparam SEL_NONE = 2'd0, SEL_MAN = 2'd1, SEL_CACTUS = 2'd2;

    // Which address to put on RAM port during active video
    reg [ADDR_WIDTH-1:0] pixel_addr_next;

    // Instantiate sprite helpers
    ian_rework_bitgen_sprite #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .SPRITE_WIDTH(SPRITE_WIDTH),
        .SPRITE_HEIGHT(SPRITE_HEIGHT),
        .SCALE(SPRITE_SCALE),
        .BASE_ADDR(SPR0_BASE)
    ) man (
        .pix_clk(pix_clk),
        .bright(bright && !loading),
        .hcount(hcount),
        .vcount(vcount),
        .pos_x(MAN_X_FIXED),
        .pos_y(man_y_reg),
        .pix_data(ram_q_b),
        .data_valid(sel_q == SEL_MAN),
        .hit(man_hit),
        .req_addr(man_req_addr),
        .vga_r(man_r),
        .vga_g(man_g),
        .vga_b(man_b),
        .opaque(man_opaque)
    );

    ian_rework_bitgen_sprite #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .SPRITE_WIDTH(SPRITE_WIDTH),
        .SPRITE_HEIGHT(SPRITE_HEIGHT),
        .SCALE(SPRITE_SCALE),
        .BASE_ADDR(SPR1_BASE)
    ) cactus (
        .pix_clk(pix_clk),
        .bright(bright && !loading),
        .hcount(hcount),
        .vcount(vcount),
        .pos_x(cactus_x_reg),
        .pos_y(CACTUS_Y_FIXED),
        .pix_data(ram_q_b),
        .data_valid(sel_q == SEL_CACTUS),
        .hit(cactus_hit),
        .req_addr(cactus_req_addr),
        .vga_r(cactus_r),
        .vga_g(cactus_g),
        .vga_b(cactus_b),
        .opaque(cactus_opaque)
    );

    // Priority: man over cactus
    always @(*) begin
        if (!bright || loading) begin
            pixel_addr_next = {ADDR_WIDTH{1'b0}}; // background/dummy
            sel_next        = SEL_NONE;
        end else if (man_hit) begin
            pixel_addr_next = man_req_addr;
            sel_next        = SEL_MAN;
        end else if (cactus_hit) begin
            pixel_addr_next = cactus_req_addr;
            sel_next        = SEL_CACTUS;
        end else begin
            pixel_addr_next = {ADDR_WIDTH{1'b0}}; // background/dummy
            sel_next        = SEL_NONE;
        end
    end

    // Register selection and address onto RAM.
    // RAM is synchronous: address is presented this cycle, ram_q_b is valid next cycle.
    // sel_q remembers which sprite requested the address so we can match data -> sprite.
    always @(posedge pix_clk) begin
        if (reset) begin
            sel_q      <= SEL_NONE;
            ram_addr_b <= {ADDR_WIDTH{1'b0}};
        end else if (loading) begin
            // Loader owns ram_addr_b while loading. Only change on issue cycle.
            sel_q <= SEL_NONE;
            if (load_phase == 2'd1)
                ram_addr_b <= POS_BASE + load_index; // RAM read for positions
        end else begin
            ram_addr_b <= pixel_addr_next;
            sel_q      <= sel_next;
        end
    end

    // Output color selection based on previous cycle's winner (sel_q)
    reg [7:0] vga_r_reg, vga_g_reg, vga_b_reg;
    always @(*) begin
        if (!bright || loading) begin
            vga_r_reg = 8'h00;
            vga_g_reg = 8'h00;
            vga_b_reg = 8'h00;
        end else if (sel_q == SEL_MAN && man_opaque) begin
            vga_r_reg = man_r;
            vga_g_reg = man_g;
            vga_b_reg = man_b;
        end else if (sel_q == SEL_CACTUS && cactus_opaque) begin
            vga_r_reg = cactus_r;
            vga_g_reg = cactus_g;
            vga_b_reg = cactus_b;
        end else begin
            vga_r_reg = BG_R;
            vga_g_reg = BG_G;
            vga_b_reg = BG_B;
        end
    end

    assign VGA_R = vga_r_reg;
    assign VGA_G = vga_g_reg;
    assign VGA_B = vga_b_reg;

endmodule
