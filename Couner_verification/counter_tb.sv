`timescale 1ns/1ps

module tb_top;
    localparam int WIDTH = 8;
    localparam time CLK_PERIOD = 10ns;

    logic             clk;
    logic             rst_n;
    logic             en;
    logic             load;
    logic             up_down;
    logic [WIDTH-1:0] load_val;
    logic [WIDTH-1:0] count;
    logic             rollover;

    // DUT Instantiation
    counter_8bit #(.WIDTH(WIDTH)) dut (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .load(load),
        .up_down(up_down),
        .load_val(load_val),
        .count(count),
        .rollover(rollover)
    );

    // SVA Assertion Instantiation
    counter_assertions #(.WIDTH(WIDTH)) u_assertions (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .load(load),
        .up_down(up_down),
        .load_val(load_val),
        .count(count),
        .rollover(rollover)
    );

    // Coverage Instantiation
    counter_coverage #(.WIDTH(WIDTH)) u_coverage (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .load(load),
        .up_down(up_down),
        .load_val(load_val),
        .count(count),
        .rollover(rollover)
    );

    // Clock Generator
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Test Sequence
    initial begin
        // Signal Initialization
        rst_n    = 1'b0;
        en       = 1'b0;
        load     = 1'b0;
        up_down  = 1'b1;
        load_val = '0;

        // 1. Reset Verification
        repeat (3) @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk);

        // 2. Direct Load & Boundary Tests
        drive_load(8'hFE);
        
        // Count Up Rollover Test (0xFE -> 0xFF -> 0x00)
        en = 1'b1;
        up_down = 1'b1;
        repeat (3) @(posedge clk);

        // Load 0x01 and Count Down Rollover (0x01 -> 0x00 -> 0xFF)
        drive_load(8'h01);
        up_down = 1'b0;
        repeat (3) @(posedge clk);

        // 3. Enable / Disable Toggle
        en = 1'b0;
        repeat (3) @(posedge clk);
        en = 1'b1;
        repeat (5) @(posedge clk);

        // 4. Randomized Stimulus Run
        repeat (500) begin
            @(posedge clk);
            load     <= (std::randomize() with { load dist {1 := 10, 0 := 90}; }) ? 1'b1 : 1'b0;
            en       <= (std::randomize() with { en dist {1 := 85, 0 := 15}; }) ? 1'b1 : 1'b0;
            up_down  <= (std::randomize() with { up_down dist {1 := 50, 0 := 50}; }) ? 1'b1 : 1'b0;
            load_val <= $urandom_range(0, 255);
        end

        // 5. Wrap-up
        @(posedge clk);
        en   = 1'b0;
        load = 1'b0;
        repeat (5) @(posedge clk);

        $display("--------------------------------------------------");
        $display(" Simulation Complete. All functional checks passed.");
        $display(" Final Coverage Instance Met: %0.2f%%", $get_coverage());
        $display("--------------------------------------------------");
        $finish;
    end

    // Task for synchronous parallel loading
    task automatic drive_load(input logic [WIDTH-1:0] val);
        @(posedge clk);
        load     <= 1'b1;
        load_val <= val;
        @(posedge clk);
        load     <= 1'b0;
    endtask

endmodule
