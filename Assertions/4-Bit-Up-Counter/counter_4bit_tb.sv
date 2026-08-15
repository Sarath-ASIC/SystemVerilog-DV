`timescale 1ns/1ps

module counter_tb;

    localparam WIDTH = 4;

    logic clk;
    logic rst_n;
    logic en;
    logic [WIDTH-1:0] count;

    
    counter #(.WIDTH(WIDTH)) dut (
        .clk   (clk),
        .rst_n (rst_n),
        .en    (en),
        .count (count)
    );

 
    initial begin 
      clk = 0;
    forever #5 clk = ~clk;
    end
  
    // Assertions
    

    // 1. Reset -> count must become 0
    assert_reset:
    assert property (@(posedge clk)
        !rst_n |=> count == '0
    );

    // 2. Enable low -> count must hold
    assert_hold:
    assert property (@(posedge clk)
        rst_n && !en |=> count == $past(count)
    );

    // 3. Enable high -> count must increment
    assert_increment:
    assert property (@(posedge clk)
        rst_n && en |=> count == ($past(count) + 1'b1)
    );

   
    initial begin
      
      $dumpfile("counter.vcd");
      $dumpvars(0, counter_tb);

        // Initial values
        rst_n = 0;
        en    = 0;

        // Apply reset
        repeat (2) @(negedge clk);

        // Release reset
        rst_n = 1;

       
        // Test 1: Hol
        en = 0;
        repeat (3) @(negedge clk);

       
        // Test 2: Count
        en = 1;
        repeat (5) @(negedge clk);
        // Test 3: Hold again
      
        en = 0;
        repeat (3) @(negedge clk);

        
        // Test 4: Rollover
        
        en = 1;
        repeat (20) @(negedge clk);

        
        // Test 5: Reset has priority over enable
        
        rst_n = 0;
        en    = 1;
        repeat (2) @(negedge clk);

        // Finish
        $finish;
    end

endmodule
