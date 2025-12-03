module vga_corrected_top(
    input  wire        reset,
    input  wire        sys_clk,     // 50 MHz
	input  wire [15:0] ram_q_b,
    output wire        VGA_HS,
    output wire        VGA_VS,
    output wire        VGA_CLK,
    output wire        VGA_BLANK_N,
    output wire        VGA_SYNC_N,
    output wire [7:0]  VGA_R,
    output wire [7:0]  VGA_G,
    output wire [7:0]  VGA_B,
	output reg  [15:0] ram_addr_b
);

    wire bright;
    wire pix_clk;
    wire [9:0] hcount, vcount;

	localparam POS_BASE = 16'h100;
    localparam MAN_BASE_ADDR    = 13'd0;
    localparam CACTUS_BASE_ADDR = 13'd4096;

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

    assign VGA_CLK     = pix_clk;
    assign VGA_BLANK_N = bright;
    assign VGA_SYNC_N  = 1'b0;

    reg [15:0] obstacle_x;
    reg [15:0] player_y;

	 // TEMPORARY: LATER CHANGE TO MEMORY MAPPED
//    obstacle_x = 10'd400;
//    player_y   = 10'd200;

    wire [12:0] player_addr;
    wire [15:0] player_data;
    wire [7:0]  player_r, player_g, player_b;
    wire        player_opaque;

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

    wire [12:0] obstacle_addr;
    wire [15:0] obstacle_data;
    wire [7:0]  obstacle_r, obstacle_g, obstacle_b;
    wire        obstacle_opaque;

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

    // We need to get rid of this. 
    sprite_rom_dp #(
        .DATA_WIDTH(16),
        .ADDR_WIDTH(13)
    ) srom (
        .clk(pix_clk),
        .addr_a(player_addr),
        .addr_b(obstacle_addr),
        .q_a(player_data),
        .q_b(obstacle_data)
    );

    reg [7:0] vga_r_reg, vga_g_reg, vga_b_reg;

    assign VGA_R = vga_r_reg;
    assign VGA_G = vga_g_reg;
    assign VGA_B = vga_b_reg;


    // pixel domain
    wire vblank_start_pix = (hcount == 10'd0) && (vcount == 10'd480);

    // sync into sys_clk
    reg vb_sync1, vb_sync2;
    always @(posedge sys_clk) begin
        vb_sync1 <= vblank_start_pix;
        vb_sync2 <= vb_sync1;
    end
    wire vblank_start = vb_sync1 & ~vb_sync2; // rising edge, now in sys_clk domain

    // State encoding
    localparam S_IDLE       = 2'd0;
    localparam S_ISSUE_ADDR = 2'd1;   // issue address to RAM
    localparam S_CAPTURE    = 2'd2;   // capture RAM data

    reg [1:0] state, state_next;
    reg [1:0] load_index, load_index_next;

    reg [15:0] obstacle_x_next;
    reg [15:0] player_y_next;
    reg [15:0] ram_addr_b_next;

    // Sequential: update registers
    always @(posedge sys_clk or negedge reset) begin
        if (!reset) begin
            state      <= S_IDLE;
            load_index <= 2'd0;
            obstacle_x <= 16'd0;
            player_y   <= 16'd0;
            ram_addr_b <= POS_BASE;
        end else begin
            state      <= state_next;
            load_index <= load_index_next;
            obstacle_x <= obstacle_x_next;
            player_y   <= player_y_next;
            ram_addr_b <= ram_addr_b_next;
        end
    end

    // Combinational: next-state and next-data logic
    always @(*) begin
        // defaults: hold values
        state_next       = state;
        load_index_next  = load_index;
        obstacle_x_next  = obstacle_x;
        player_y_next    = player_y;
        ram_addr_b_next  = ram_addr_b;

        case (state)
            S_IDLE: begin
                if (vblank_start) begin
                    load_index_next = 2'd0;
                    ram_addr_b_next = POS_BASE;   // first word
                    state_next      = S_ISSUE_ADDR;
                end
            end

            S_ISSUE_ADDR: begin
                // address already set; just move to capture on next cycle
                state_next = S_CAPTURE;
            end

            S_CAPTURE: begin
                // capture current RAM word based on index
                if (load_index == 2'd0) begin
                    player_y_next = ram_q_b;
                end else if (load_index == 2'd1) begin
                    obstacle_x_next = ram_q_b;
                end

                // decide whether to keep loading or finish
                if (load_index == 2'd1) begin
                    // loaded both words: POS_BASE (x), POS_BASE+1 (y)
                    state_next      = S_IDLE;
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


    // // State encoding
    // localparam S_IDLE       = 2'd0;
    // localparam S_ISSUE_ADDR = 2'd1;   // issue address to RAM
    // localparam S_CAPTURE    = 2'd2;   // capture RAM data

    // // Reg's for FSM
    // reg [1:0] state;       // current state
    // reg [1:0] load_index;  // which position word is being loaded
    // // Next state logic for loading positions
    // always @(posedge sys_clk or negedge reset) begin
    //     if (!reset) begin
    //         state <= S_IDLE;
    //     end else begin
    //         case (state)
    //             S_IDLE: begin
    //                 // if vblank start, begin loading positions
    //                 if (vblank_start) begin
    //                     state <= S_ISSUE_ADDR;
    //                 end
    //                 // else remain in idle
    //                 else begin
    //                     state <= S_IDLE;
    //                 end
    //             end
    //             S_ISSUE_ADDR: begin
    //                 state <= S_CAPTURE;
    //             end
    //             S_CAPTURE: begin
    //                 if (load_index == 2'd1) begin
    //                     state <= S_IDLE;
    //                 end else begin
    //                     state <= S_ISSUE_ADDR;
    //                 end
    //             end
    //             default: state <= S_IDLE;
    //         endcase
    //     end  
    // end

    // // Output logic for loading positions
    // always @(*) begin
    //     load_index  = 2'd0;
    //     case (state)
    //         S_IDLE: begin
    //             load_index  = 2'd0;
    //         end
    //         S_ISSUE_ADDR: begin
    //             load_index  = load_index; // keep current index
    //             ram_addr_b = POS_BASE + load_index; // RAM read for positions
    //         end
    //         S_CAPTURE: begin
    //             obstacle_x = (load_index == 2'd0) ? ram_q_b : obstacle_x;
    //             player_y = (load_index == 2'd1) ? ram_q_b : player_y;
    //             load_index  = load_index + 2'd1; // increment index
    //         end
    //         default: begin
    //             load_index  = 2'd0;
    //         end
    //     endcase
    // end

// q: how does this work? How does each pixel know if it's a player pixel or obstacle pixel?
// A: The pixel being drawn is determined by hcount and vcount. Each sprite module
//    checks if the current hcount/vcount is within its sprite area, and outputs the appropriate color and opacity signals.
// q: where do those get assigned to vga_r/g/b?
// A: At the end of this module, there's a combinational block that decides the final VGA_R/G/B values based on the opacity of the player and obstacle sprites.
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
            vga_r_reg = 8'h88;
            vga_g_reg = 8'hCC;
            vga_b_reg = 8'h88;
        end
    end

endmodule
