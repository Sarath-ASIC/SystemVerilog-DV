`timescale 1ns/1ps

module counter_ip_tb;

    // Testbench signals
    logic       clk;
    logic       rst_n;
    logic       enable;
    logic       load;
    logic [7:0] load_value;

    logic [7:0] count;

  
    counter_ip #(
        .WIDTH(8)
    ) 
  dut1 (
        .clk        (clk),
        .rst_n      (rst_n),
        .enable     (enable),
        .load       (load),
        .load_value (load_value),
        .count      (count)
    );

    
    // Clock generation
    // 10 ns period
   
    initial begin
        clk = 0;

        forever #5 clk = ~clk;
    end

    
    // Stimulus
    
    initial begin

        // Initial values
        rst_n      = 0;
        enable     = 0;
        load       = 0;
        load_value = 8'd0;

        // Hold reset for two clock cycles
        #20;

        rst_n = 1;

        // --------------------------------------------
        // Test 1: Enable counter
        // --------------------------------------------
        enable = 1;

        #50;

        // --------------------------------------------
        // Test 2: Disable -> counter should hold
        // --------------------------------------------
        enable = 0;

        #30;

        // --------------------------------------------
        // Test 3: Load value
        // --------------------------------------------
        load       = 1;
        load_value = 8'd100;

        #10;

        load = 0;

        // --------------------------------------------
        // Test 4: Count from loaded value
        // --------------------------------------------
        enable = 1;

        #30;

        // --------------------------------------------
        // Test 5: Load and enable simultaneously
        // Load should have priority
        // --------------------------------------------
        load       = 1;
        enable     = 1;
        load_value = 8'd200;

        #10;

        load = 0;

        // --------------------------------------------
        // Continue counting
        // --------------------------------------------
        #30;

        // --------------------------------------------
        // Test 6: Wrap-around
        // Load 255
        // --------------------------------------------
        load       = 1;
        enable     = 0;
        load_value = 8'd255;

        #10;

        load   = 0;
        enable = 1;

        // 255 -> 0
        #10;

        // Stop simulation
        $finish;

    end

endmodule
