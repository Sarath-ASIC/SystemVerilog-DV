module counter_assertions #(
    parameter int WIDTH = 8
)(
    input logic             clk,
    input logic             rst_n,
    input logic             en,
    input logic             load,
    input logic             up_down,
    input logic [WIDTH-1:0] load_val,
    input logic [WIDTH-1:0] count,
    input logic             rollover
);

    localparam logic [WIDTH-1:0] MAX_VAL = {WIDTH{1'b1}};
    localparam logic [WIDTH-1:0] MIN_VAL = {WIDTH{1'b0}};

    default clocking def_clk @(posedge clk); endclocking
    default disable iff (!rst_n);

    // Reset check
    property p_sync_reset;
        !rst_n |=> (count == '0 && rollover == 1'b0);
    endproperty
    a_sync_reset: assert property (p_sync_reset)
        else $error("Assertion Failed: Synchronous reset failed to clear count/rollover");

    // Parallel load priority check
    property p_load_priority;
        load |=> (count == $past(load_val) && rollover == 1'b0);
    endproperty
    a_load_priority: assert property (p_load_priority)
        else $error("Assertion Failed: Load operation or priority failure");

    // Hold state when disabled
    property p_hold_when_disabled;
        (!load && !en) |=> ($stable(count) && rollover == 1'b0);
    endproperty
    a_hold_disabled: assert property (p_hold_when_disabled)
        else $error("Assertion Failed: Count altered while enable is deasserted");

    // Up-count increment
    property p_count_up;
        (!load && en && up_down && ($past(count) != MAX_VAL)) |=> (count == ($past(count) + 1'b1));
    endproperty
    a_count_up: assert property (p_count_up)
        else $error("Assertion Failed: Up-counter failed standard increment");

    // Down-count decrement
    property p_count_down;
        (!load && en && !up_down && ($past(count) != MIN_VAL)) |=> (count == ($past(count) - 1'b1));
    endproperty
    a_count_down: assert property (p_count_down)
        else $error("Assertion Failed: Down-counter failed standard decrement");

    // Rollover: 0xFF -> 0x00 on Count Up
    property p_rollover_up;
        (!load && en && up_down && ($past(count) == MAX_VAL)) |=> (count == MIN_VAL && rollover == 1'b1);
    endproperty
    a_rollover_up: assert property (p_rollover_up)
        else $error("Assertion Failed: Rollover flag/wrap failed on Up-Count overflow");

    // Rollover: 0x00 -> 0xFF on Count Down
    property p_rollover_down;
        (!load && en && !up_down && ($past(count) == MIN_VAL)) |=> (count == MAX_VAL && rollover == 1'b1);
    endproperty
    a_rollover_down: assert property (p_rollover_down)
        else $error("Assertion Failed: Rollover flag/wrap failed on Down-Count underflow");

    // Rollover pulse duration is strictly 1 cycle
    property p_rollover_one_cycle;
        rollover |=> !rollover;
    endproperty
    a_rollover_one_cycle: assert property (p_rollover_one_cycle)
        else $error("Assertion Failed: Rollover signal remained asserted > 1 clock cycle");

endmodule
