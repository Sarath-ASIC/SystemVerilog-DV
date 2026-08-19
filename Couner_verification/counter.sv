module counter_8bit #(
    parameter int WIDTH = 8
)(
    input  logic             clk,
    input  logic             rst_n,      // Active-low synchronous reset
    input  logic             en,         // Count enable
    input  logic             load,       // Synchronous load (highest priority over count)
    input  logic             up_down,    // 1 = Count Up, 0 = Count Down
    input  logic [WIDTH-1:0] load_val,   // Parallel load data
    output logic [WIDTH-1:0] count,      // Current counter value
    output logic             rollover    // High for 1 cycle when terminal count wraps
);

    localparam logic [WIDTH-1:0] MAX_VAL = {WIDTH{1'b1}};
    localparam logic [WIDTH-1:0] MIN_VAL = {WIDTH{1'b0}};

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            count    <= '0;
            rollover <= 1'b0;
        end else if (load) begin
            count    <= load_val;
            rollover <= 1'b0;
        end else if (en) begin
            if (up_down) begin
                count    <= count + 1'b1;
                rollover <= (count == MAX_VAL);
            end else begin
                count    <= count - 1'b1;
                rollover <= (count == MIN_VAL);
            end
        end else begin
            rollover <= 1'b0;
        end
    end

endmodule
