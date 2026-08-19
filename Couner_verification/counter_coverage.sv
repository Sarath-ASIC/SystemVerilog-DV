module counter_coverage #(
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

    covergroup cg_counter @(posedge clk iff rst_n);
        option.per_instance = 1;
        option.name = "cg_counter_metrics";

        cp_enable: coverpoint en {
            bins active   = {1'b1};
            bins inactive = {1'b0};
        }

        cp_up_down: coverpoint up_down {
            bins up   = {1'b1};
            bins down = {1'b0};
        }

        cp_load: coverpoint load {
            bins load_active = {1'b1};
            bins no_load     = {1'b0};
        }

        cp_load_val: coverpoint load_val {
            bins min_val       = {'h00};
            bins max_val       = {'hFF};
            bins walking_ones  = {'h01, 'h02, 'h04, 'h08, 'h10, 'h20, 'h40, 'h80};
            bins mid_range[4]  = {['h03:'hFE]};
        }

        cp_count: coverpoint count {
            bins zero        = {'h00};
            bins max         = {'hFF};
            bins quarters[4] = {[0:255]};
            bins wrap_up     = ('hFF => 'h00);
            bins wrap_down   = ('h00 => 'hFF);
        }

        cp_rollover: coverpoint rollover {
            bins triggered = {1'b1};
            bins idle      = {1'b0};
        }

        // Cross coverages to ensure all modes are hit
        cross_op_modes: cross cp_enable, cp_up_down, cp_load;
        cross_wrap_up:   cross cp_rollover, cp_up_down, cp_enable {
            bins up_rollover   = binsof(cp_rollover.triggered) && binsof(cp_up_down.up) && binsof(cp_enable.active);
            bins down_rollover = binsof(cp_rollover.triggered) && binsof(cp_up_down.down) && binsof(cp_enable.active);
        }

    endgroup

    cg_counter cg_inst = new();

endmodule
