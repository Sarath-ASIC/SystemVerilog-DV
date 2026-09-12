interface dma_if #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
)(
    input logic clk,
    input logic rst_n
);

    // Control / Register Interface
    logic                  ctrl_wr_en;
    logic [3:0]            ctrl_addr;
    logic [DATA_WIDTH-1:0] ctrl_wdata;
    logic [DATA_WIDTH-1:0] ctrl_rdata;

    // Master Read Interface
    logic [ADDR_WIDTH-1:0] m_rd_addr;
    logic                  m_rd_req;
    logic                  m_rd_ack;
    logic [DATA_WIDTH-1:0] m_rd_data;
    logic                  m_rd_valid;

    // Master Write Interface
    logic [ADDR_WIDTH-1:0] m_wr_addr;
    logic [DATA_WIDTH-1:0] m_wr_data;
    logic                  m_wr_req;
    logic                  m_wr_ack;

    // Status / IRQ
    logic                  dma_done_irq;
    logic                  dma_busy;

    // Master Clocking Block for TB Driver
    clocking drv_cb @(posedge clk);
        default input #1step output #1ns;
        output ctrl_wr_en, ctrl_addr, ctrl_wdata;
        output m_rd_ack, m_rd_data, m_rd_valid;
        output m_wr_ack;
        input  ctrl_rdata, m_rd_addr, m_rd_req;
        input  m_wr_addr, m_wr_data, m_wr_req;
        input  dma_done_irq, dma_busy;
    endclocking

endinterface : dma_if
