module dma_assertions #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
)(
    input logic                   clk,
    input logic                   rst_n,

    // Monitored Interface Signals
    input logic                   ctrl_wr_en,
    input logic [3:0]             ctrl_addr,
    input logic [DATA_WIDTH-1:0]  ctrl_wdata,

    input logic [ADDR_WIDTH-1:0]  m_rd_addr,
    input logic                   m_rd_req,
    input logic                   m_rd_ack,
    input logic [DATA_WIDTH-1:0]  m_rd_data,
    input logic                   m_rd_valid,

    input logic [ADDR_WIDTH-1:0]  m_wr_addr,
    input logic [DATA_WIDTH-1:0]  m_wr_data,
    input logic                   m_wr_req,
    input logic                   m_wr_ack,

    input logic                   dma_done_irq,
    input logic                   dma_busy
);

    // 1. Read request address alignment (32-bit word aligned: lower 2 bits 2'b00)
    property p_rd_addr_aligned;
        @(posedge clk) disable iff (!rst_n)
        m_rd_req |-> (m_rd_addr[1:0] == 2'b00);
    endproperty
    assert_rd_addr_aligned: assert property (p_rd_addr_aligned)
        else $error("[SVA FAIL] m_rd_addr is not word-aligned: 0x%08h", m_rd_addr);

    // 2. Write request address alignment
    property p_wr_addr_aligned;
        @(posedge clk) disable iff (!rst_n)
        m_wr_req |-> (m_wr_addr[1:0] == 2'b00);
    endproperty
    assert_wr_addr_aligned: assert property (p_wr_addr_aligned)
        else $error("[SVA FAIL] m_wr_addr is not word-aligned: 0x%08h", m_wr_addr);

    // 3. Read address stability during active request until acked
    property p_rd_addr_stable_until_ack;
        @(posedge clk) disable iff (!rst_n)
        (m_rd_req && !m_rd_ack) |=> ($stable(m_rd_addr) && m_rd_req);
    endproperty
    assert_rd_addr_stable: assert property (p_rd_addr_stable_until_ack)
        else $error("[SVA FAIL] m_rd_addr changed before m_rd_ack arrived!");

    // 4. Write data/address stability during active write request until acked
    property p_wr_payload_stable_until_ack;
        @(posedge clk) disable iff (!rst_n)
        (m_wr_req && !m_wr_ack) |=> ($stable(m_wr_addr) && $stable(m_wr_data) && m_wr_req);
    endproperty
    assert_wr_payload_stable: assert property (p_wr_payload_stable_until_ack)
        else $error("[SVA FAIL] Write payload/address shifted before m_wr_ack!");

    // 5. DMA must not be busy on reset release
    property p_idle_on_reset;
        @(posedge clk) $rose(rst_n) |-> (!dma_busy && !dma_done_irq);
    endproperty
    assert_idle_on_reset: assert property (p_idle_on_reset)
        else $error("[SVA FAIL] DMA active immediately upon reset release!");

    // 6. DMA done IRQ implies dma_busy drops in the immediate next cycle
    property p_done_drops_busy;
        @(posedge clk) disable iff (!rst_n)
        dma_done_irq |=> !dma_busy;
    endproperty
    assert_done_drops_busy: assert property (p_done_drops_busy)
        else $error("[SVA FAIL] dma_busy did not drop after dma_done_irq!");

    // 7. No simultaneous read and write master requests
    property p_no_simultaneous_rw;
        @(posedge clk) disable iff (!rst_n)
        !(m_rd_req && m_wr_req);
    endproperty
    assert_no_simultaneous_rw: assert property (p_no_simultaneous_rw)
        else $error("[SVA FAIL] Simultaneous m_rd_req and m_wr_req asserted!");

endmodule : dma_assertions
