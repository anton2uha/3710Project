module vga_corrected_top(
    input  wire        sys_clk,     // 50 MHz
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

    localparam MAN_BASE_ADDR    = 13'd0;
    localparam CACTUS_BASE_ADDR = 13'd4096;

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

    wire [15:0] obstacle_x;
    wire [15:0] player_y;

	 // TEMPORARY: LATER CHANGE TO MEMORY MAPPED
    assign obstacle_x = 10'd400;
    assign player_y   = 10'd200;

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
    // sprite_rom_dp #(
    //     .DATA_WIDTH(16),
    //     .ADDR_WIDTH(13)
    // ) srom (
    //     .clk(pix_clk),
    //     .addr_a(player_addr),
    //     .addr_b(obstacle_addr),
    //     .q_a(player_data),
    //     .q_b(obstacle_data)
    // );

    reg [7:0] vga_r_reg, vga_g_reg, vga_b_reg;

    assign VGA_R = vga_r_reg;
    assign VGA_G = vga_g_reg;
    assign VGA_B = vga_b_reg;

    
    // Start of loading position logic
    wire vblank_start = (hcount == 10'd0) && (vcount == 10'd480); // start of vertical blank for 640x480
    // State encoding
    localparam S_IDLE       = 2'd0;
    localparam S_ISSUE_ADDR = 2'd1;   // issue address to RAM
    localparam S_CAPTURE    = 2'd2;   // capture RAM data

    // Reg's for FSM
    reg [1:0] state;       // current state

    // reg       loading;
    reg [1:0] load_index;  // which position word is being loaded
    // reg [1:0] load_phase;  // will be driven by combinational "output" block

    // reg [15:0] cactus_x_reg;
    // reg [15:0] man_y_reg;
    // Next state logic for loading positions
    always @(posedge sys_clk or posedge reset) begin
        if (reset) begin
            state       <= S_IDLE;
        end else begin
            case (state)
                S_IDLE: begin
                    // if vblank start, begin loading positions
                    if (vblank_start) begin
                        state <= S_ISSUE_ADDR;
                    end
                    // else remain in idle
                    else begin
                        state <= S_IDLE;
                    end
                end
                S_ISSUE_ADDR: begin
                    state <= S_CAPTURE;
                end
                S_CAPTURE: begin
                    if (load_index == 2'd1) begin
                        state <= S_IDLE;
                    end else begin
                        state <= S_ISSUE_ADDR;
                    end
                end
                default: state <= S_IDLE;
        end
    end

    // Output logic for loading positions
    always @(*) begin
        load_index  = 2'd0;
        case (state)
            S_IDLE: begin
                load_index  = 2'd0;
            end
            S_ISSUE_ADDR: begin
                load_index  = load_index; // keep current index
                ram_addr_b = POS_BASE + load_index; // RAM read for positions
            end
            S_CAPTURE: begin
                obstacle_x = (load_index == 2'd0) ? ram_q_b : obstacle_x;
                player_y = (load_index == 2'd1) ? ram_q_b : player_y;
                load_index  = load_index + 2'd1; // increment index
            end
            default: begin
                load_index  = 2'd0;
            end
        endcase
    end

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
