module vga_top(
    input  wire        reset,
    input  wire        sys_clk,     // 50 MHz
    input  wire [15:0] ram_q_b,
    output reg  [15:0] ram_addr_b,
    output reg  [15:0] ram_data_b,
    output reg         ram_we_b,
    output wire        VGA_HS,
    output wire        VGA_VS,
    output wire        VGA_CLK,
    output wire        VGA_BLANK_N,
    output wire        VGA_SYNC_N,
    output wire [7:0]  VGA_R,
    output wire [7:0]  VGA_G,
    output wire [7:0]  VGA_B
);

    wire bright;
    wire pix_clk;
    wire [9:0] hcount, vcount;

    localparam POS_BASE          = 16'h0100;
    localparam MAN_BASE_ADDR     = 13'd0;
    localparam CACTUS_BASE_ADDR  = 13'd4096;
	localparam BG_BASE_ADDR     = 17'd5120;
    localparam VBLANK_FLAG_ADDR  = 16'hFFFE;

    assign VGA_CLK     = pix_clk;
    assign VGA_BLANK_N = bright;
    assign VGA_SYNC_N  = 1'b0;

    reg [15:0] obstacle_x;
    reg [15:0] player_y;

    // Sprite ROM interface
    wire [12:0] player_addr;
    wire [15:0] player_data;
    wire [7:0]  player_r, player_g, player_b;
    wire        player_opaque;

    wire [12:0] obstacle_addr;
    wire [15:0] obstacle_data;
    wire [7:0]  obstacle_r, obstacle_g, obstacle_b;
    wire        obstacle_opaque;
	 
	wire [16:0] bg_addr;
    wire [15:0] bg_data;
    wire [7:0] bg_r, bg_g, bg_b;

    vga_control vc (
        .reset(reset),
        .clk(sys_clk),
        .hsync(VGA_HS),
        .vsync(VGA_VS),
        .bright(bright),
        .pix_clk_out(pix_clk),
        .hcount(hcount),
        .vcount(vcount)
    );

    bitgen_player_sprite #(
        .BASE_ADDR(MAN_BASE_ADDR)
    ) player (
        .pix_clk(pix_clk),
        .bright(bright),
        .hcount(hcount),
        .vcount(vcount),
        .sprite_data(player_data),
        .sprite_addr(player_addr),
        .vga_r(player_r),
        .vga_g(player_g),
        .vga_b(player_b),
        .pixel_opaque(player_opaque),
        .player_y(player_y)
    );
	 
	bitgen_background_sprite #(
        .BASE_ADDR(BG_BASE_ADDR)
    ) background (
        .pix_clk(pix_clk),
        .bright(bright),
        .hcount(hcount),
        .vcount(vcount),
        .bg_data(bg_data),
        .bg_addr(bg_addr),
        .vga_r(bg_r),
        .vga_g(bg_g),
        .vga_b(bg_b)
    );

    bitgen_obstacle_sprite #(
        .BASE_ADDR(CACTUS_BASE_ADDR)
    ) obstacle (
        .pix_clk(pix_clk),
        .bright(bright),
        .hcount(hcount),
        .vcount(vcount),
        .sprite_data(obstacle_data),
        .sprite_addr(obstacle_addr),
        .vga_r(obstacle_r),
        .vga_g(obstacle_g),
        .vga_b(obstacle_b),
        .pixel_opaque(obstacle_opaque),
        .obstacle_x(obstacle_x)
    );
	 wire [16:0] mux_addr_b = obstacle_opaque ? {4'b0, obstacle_addr} : bg_addr;
	wire [15:0] mux_data_b;

	sprite_rom_dp #(
		 .DATA_WIDTH(16),
		 .ADDR_WIDTH(17)
	) srom (
		 .clk(pix_clk),
		 .addr_a({4'b0, player_addr}),
		 .addr_b(mux_addr_b),
		 .q_a(player_data),
		 .q_b(mux_data_b)
	);

    // Route data to both obstacle and background
    assign obstacle_data = mux_data_b;
    assign bg_data = mux_data_b;

    reg [7:0] vga_r_reg, vga_g_reg, vga_b_reg;
    assign VGA_R = vga_r_reg;
    assign VGA_G = vga_g_reg;
    assign VGA_B = vga_b_reg;
    wire vblank_start_pix = (hcount == 10'd0) && (vcount == 10'd480);

    // sync into sys_clk
    reg vb_sync1, vb_sync2;
    always @(posedge sys_clk) begin
        vb_sync1 <= vblank_start_pix;
        vb_sync2 <= vb_sync1;
    end
    wire vblank_start = vb_sync1 & ~vb_sync2;

    // State encoding
    localparam S_IDLE        = 2'd0;
    localparam S_WRITE_FLAG  = 2'd1;
    localparam S_ISSUE_ADDR  = 2'd2;
    localparam S_CAPTURE     = 2'd3;

    reg [1:0] state, state_next;
    reg [1:0] load_index, load_index_next;

    reg [15:0] obstacle_x_next;
    reg [15:0] player_y_next;
    reg [15:0] ram_addr_b_next;
    reg [15:0] ram_data_b_next;
    reg        ram_we_b_next;

    // Sequential update registers
    always @(posedge sys_clk or negedge reset) begin
        if (!reset) begin
            state      <= S_IDLE;
            load_index <= 2'd0;
            obstacle_x <= 16'd0;
            player_y   <= 16'd0;
            ram_addr_b <= POS_BASE;
            ram_data_b <= 16'd0;
            ram_we_b   <= 1'b0;
        end else begin
            state      <= state_next;
            load_index <= load_index_next;
            obstacle_x <= obstacle_x_next;
            player_y   <= player_y_next;
            ram_addr_b <= ram_addr_b_next;
            ram_data_b <= ram_data_b_next;
            ram_we_b   <= ram_we_b_next;
        end
    end

    // Combinational: next-state and next-data logic
    always @(*) begin
        state_next       = state;
        load_index_next  = load_index;
        obstacle_x_next  = obstacle_x;
        player_y_next    = player_y;
        ram_addr_b_next  = ram_addr_b;
        ram_data_b_next  = ram_data_b;
        ram_we_b_next    = 1'b0;

        case (state)
            S_IDLE: begin
                if (vblank_start) begin
                    ram_addr_b_next = VBLANK_FLAG_ADDR;
                    ram_data_b_next = 16'h0001;
                    ram_we_b_next   = 1'b1;
                    load_index_next = 2'd0;
                    state_next      = S_WRITE_FLAG;
                end
            end

            S_WRITE_FLAG: begin
                ram_we_b_next   = 1'b0; // back to read
                ram_addr_b_next = POS_BASE;  // first word: player_y
                state_next      = S_ISSUE_ADDR;
            end

            S_ISSUE_ADDR: begin
                state_next = S_CAPTURE;
            end

            S_CAPTURE: begin
                if (load_index == 2'd0) begin
                    player_y_next = ram_q_b;
                end else if (load_index == 2'd1) begin
                    obstacle_x_next = ram_q_b;
                end

                if (load_index == 2'd1) begin
                    state_next      = S_IDLE;// done loading both
                end else begin
                    // increment index and issue next address
                    load_index_next = load_index + 2'd1;
                    ram_addr_b_next = POS_BASE + (load_index + 2'd1);
                    state_next      = S_ISSUE_ADDR;
                end
            end

            default: begin
                state_next      = S_IDLE;
                load_index_next = 2'd0;
            end
        endcase
    end

    // Final color layering muxx
    always @(*) begin
        if (!bright) begin
            vga_r_reg = 8'h00;
            vga_g_reg = 8'h00;
            vga_b_reg = 8'h00;
        end else if (player_opaque) begin
            vga_r_reg = player_r;
            vga_g_reg = player_g;
            vga_b_reg = player_b;
        end else if (obstacle_opaque) begin
            vga_r_reg = obstacle_r;
            vga_g_reg = obstacle_g;
            vga_b_reg = obstacle_b;
        end else begin
            vga_r_reg = bg_r;
            vga_g_reg = bg_g;
            vga_b_reg = bg_b;
        end
    end

endmodule
