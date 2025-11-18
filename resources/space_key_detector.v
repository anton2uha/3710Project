`timescale 1ns / 1ps

// Module:       space_key_detector
// Description:  Detects spacebar

module space_key_detector (
    input  wire CLOCK_50,    
    input  wire reset,      

    inout  wire PS2_CLK,    
    inout  wire PS2_DAT,    

    output reg  space_pressed_pulse, 
    output reg  space_is_down        
);

    

    wire [7:0] scan_code;
    wire       scan_valid;
    wire       cmd_sent;
    wire       cmd_error;

    // Don't need to send commands to the PS2
    wire [7:0] dummy_cmd  = 8'h00;
    wire       dummy_send = 1'b0;

    PS2_Controller #(
        .INITIALIZE_MOUSE(1'b0)   // Don't use mouse
    ) ps2_ctrl_inst (
        .CLOCK_50   (CLOCK_50),
        .reset      (reset),

        .the_command(dummy_cmd),
        .send_command(dummy_send),

        .PS2_CLK    (PS2_CLK),
        .PS2_DAT    (PS2_DAT),

        .command_was_sent            (cmd_sent),   
        .error_communication_timed_out(cmd_error),

        .received_data    (scan_code),            
        .received_data_en (scan_valid)            
    );


   reg break_seen;  // Whether the previous byte was 0xF0 (break prefix)

	localparam [7:0] SC_SPACE = 8'h29;  // Spacebar make code
	localparam [7:0] SC_BREAK = 8'hF0;  // Break prefix (0xF0)

	always @(posedge CLOCK_50 or posedge reset) begin
		 if (reset) begin
			  break_seen          <= 1'b0;
			  space_pressed_pulse <= 1'b0;
			  space_is_down       <= 1'b0;
		 end else begin
			  // space_pressed_pulse is only 1 clock wide, so reset to 0 every cycle
			  space_pressed_pulse <= 1'b0;

			  if (scan_valid) begin
					// If 0xF0 is received, the next byte indicates which key was released
					if (scan_code == SC_BREAK) begin
						 break_seen <= 1'b1;
					end
					else begin
						 // If the previous byte was 0xF0, this byte is the break code 
						 if (break_seen) begin
							  if (scan_code == SC_SPACE) begin
									// Spacebar was released
									space_is_down <= 1'b0;
							  end
							  break_seen <= 1'b0;
						 end
						 // Otherwise, this byte is a make code (key press)
						 else begin
							  if (scan_code == SC_SPACE) begin
									// Spacebar was pressed:
									//  - space_pressed_pulse: 1-clock pulse for actions
									//  - space_is_down: stays high while the key is held down
									space_pressed_pulse <= 1'b1;
									space_is_down       <= 1'b1;
							  end
						 end
					end
			  end
		 end
	end


endmodule
