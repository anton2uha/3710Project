module tb_true_dual_port_ram_single_clock;
    
    // Setup
    parameter DATA_WIDTH = 16;
    parameter ADDR_WIDTH = 16;

    reg [(DATA_WIDTH-1):0] data_a;
    reg [(DATA_WIDTH-1):0] data_b;
    reg [(ADDR_WIDTH-1):0] addr_a;
    reg [(ADDR_WIDTH-1):0] addr_b;
    reg we_a;
    reg we_b;
    reg clk;

    wire [(DATA_WIDTH-1):0] q_a;
    wire [(DATA_WIDTH-1):0] q_b;

    true_dual_port_ram_single_clock uut (
        .data_a(data_a), 
        .data_b(data_b), 
        .addr_a(addr_a), 
        .addr_b(addr_b), 
        .we_a(we_a), 
        .we_b(we_b), 
        .clk(clk), 
        .q_a(q_a), 
        .q_b(q_b)
    );

    // Generate clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin

        // Monitor all inputs and outputs
        $monitor("we_a: %b | addr_a: %h | data_a: %h | q_a: %h || we_b: %b | addr_b: %h | data_b: %h | q_b: %h", 
                  we_a, addr_a, data_a, q_a, we_b, addr_b, data_b, q_b);

        // Initialize inputs
        data_a = 0;
        data_b = 0;
        addr_a = 0;
        addr_b = 0;
        we_a = 0;
        we_b = 0;

        #10;

        // Test writing to port A
        $display("Writing to port A");
        we_a = 1; addr_a = 4; data_a = 16'hA5A5;
        #10;
        we_a = 0;
        $display("Disable write to port A");
        #20;

        // Test writing to port B
        $display("Writing to port B");
        we_b = 1; addr_b = 8; data_b = 16'h5A5A;
        #10;
        we_b = 0;
        $display("Disable write to port B");
        #20;

        // Test write to both ports
        $display("Writing to both ports");
        we_a = 1; addr_a = 12; data_a = 16'hFFFF;
        we_b = 1; addr_b = 16; data_b = 16'h0000;
        #10;

        we_a = 0;
        we_b = 0;
        $display("Disable write to both ports");
        #20;

        // Test write to both ports at the same address
        $display("Writing to both ports. (Should be FFFF)");
        we_a = 1; addr_a = 20; data_a = 16'hFFFF;
        we_b = 1; addr_b = 20; data_b = 16'h1111;
        #10;

        we_a = 0;
        we_b = 0;
        $display("Disable write to both ports");
        #20;
		  
		  $display("check that all written ports are populated correctly");
		  addr_a = 16'h0;
        addr_b = 16'h1;
		  #20;
		  
		  addr_a = 16'h2;
		  #20;
		  
		  addr_a = 16'd510;
		  addr_b = 16'd511;
		  #20;
		  
		  addr_a = 16'd512;
		  addr_b = 16'd513;
		  #20;
		  
        $finish;
    end
endmodule