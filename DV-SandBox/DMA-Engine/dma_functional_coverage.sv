module dma_coverage #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
)(
    input logic                   clk,
    input logic                   rst_n,

    input logic                   ctrl_wr_en,
    input logic [3:0]             ctrl_addr,
    input logic [DATA_WIDTH-1:0]  ctrl_wdata,

    input logic [ADDR_WIDTH-1:0]  m_rd_addr,
    input logic                   m_rd_req,
    input logic                   m_rd_ack,
    input logic                   m_rd_valid,

    input logic [ADDR_WIDTH-1:0]  m_wr_addr,
    input logic                   m_wr_req,
    input logic                   m_wr_ack,

    input logic                   dma_done_irq,
    input logic                   dma_busy
);

    // Covergroup 1: Register accesses and configurations
    covergroup cg_registers @(posedge clk iff (rst_n && ctrl_wr_en));
        option.per_instance = 1;
        option.name = "cg_dma_reg_writes";

        cp_reg_address: coverpoint ctrl_addr {
            bins src_addr = {4'h0};
            bins dst_addr = {4'h4};
            bins len      = {4'h8};
            bins ctrl     = {4'hC};
        }

        cp_transfer_len: coverpoint ctrl_wdata iff (ctrl_addr == 4'h8) {
            bins zero_len   = {0};
            bins single_wd  = {1};
            bins small_burst = {[2:4]};
            bins med_burst   = {[5:16]};
            bins large_burst = {[17:256]};
        }

        cp_ctrl_commands: coverpoint ctrl_wdata[1:0] iff (ctrl_addr == 4'hC) {
            bins start_pulse = {2'b01};
            bins soft_reset  = {2'b10};
        }
    endgroup

    // Covergroup 2: Bus handshaking latencies
    covergroup cg_bus_handshake @(posedge clk iff rst_n);
        option.per_instance = 1;
        option.name = "cg_dma_handshake";

        cp_rd_ack_latency: coverpoint (m_rd_req && m_rd_ack) {
            bins immediate_ack = {1};
        }

        cp_wr_ack_latency: coverpoint (m_wr_req && m_wr_ack) {
            bins immediate_ack = {1};
        }

        cp_irq_event: coverpoint dma_done_irq {
            bins triggered = {1};
        }
    endgroup

    cg_registers     cov_regs      = new();
    cg_bus_handshake cov_handshake = new();

endmodule : dma_coverage
