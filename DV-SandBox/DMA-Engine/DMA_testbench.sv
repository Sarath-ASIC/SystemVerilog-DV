`timescale 1ns / 1ps

module tb_top;

    localparam DATA_WIDTH = 32;
    localparam ADDR_WIDTH = 32;
    localparam CLK_PERIOD = 10; // 100 MHz

    logic clk;
    logic rst_n;

    // Clock Generation
    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    // Interface Instantiation
    dma_if #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) vif (
        .clk(clk),
        .rst_n(rst_n)
    );

    // DUT Instantiation
    dma_engine #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_dut (
        .clk          (vif.clk),
        .rst_n        (vif.rst_n),
        .ctrl_wr_en   (vif.ctrl_wr_en),
        .ctrl_addr    (vif.ctrl_addr),
        .ctrl_wdata   (vif.ctrl_wdata),
        .ctrl_rdata   (vif.ctrl_rdata),
        .m_rd_addr    (vif.m_rd_addr),
        .m_rd_req     (vif.m_rd_req),
        .m_rd_ack     (vif.m_rd_ack),
        .m_rd_data    (vif.m_rd_data),
        .m_rd_valid   (vif.m_rd_valid),
        .m_wr_addr    (vif.m_wr_addr),
        .m_wr_data    (vif.m_wr_data),
        .m_wr_req     (vif.m_wr_req),
        .m_wr_ack     (vif.m_wr_ack),
        .dma_done_irq (vif.dma_done_irq),
        .dma_busy     (vif.dma_busy)
    );

    // Bind Assertion Model
    bind dma_engine dma_assertions #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_sva (
        .clk          (clk),
        .rst_n        (rst_n),
        .ctrl_wr_en   (ctrl_wr_en),
        .ctrl_addr    (ctrl_addr),
        .ctrl_wdata   (ctrl_wdata),
        .m_rd_addr    (m_rd_addr),
        .m_rd_req     (m_rd_req),
        .m_rd_ack     (m_rd_ack),
        .m_rd_data    (m_rd_data),
        .m_rd_valid   (m_rd_valid),
        .m_wr_addr    (m_wr_addr),
        .m_wr_data    (m_wr_data),
        .m_wr_req     (m_wr_req),
        .m_wr_ack     (m_wr_ack),
        .dma_done_irq (dma_done_irq),
        .dma_busy     (dma_busy)
    );

    // Bind Coverage Model
    bind dma_engine dma_coverage #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_cov (
        .clk          (clk),
        .rst_n        (rst_n),
        .ctrl_wr_en   (ctrl_wr_en),
        .ctrl_addr    (ctrl_addr),
        .ctrl_wdata   (ctrl_wdata),
        .m_rd_addr    (m_rd_addr),
        .m_rd_req     (m_rd_req),
        .m_rd_ack     (m_rd_ack),
        .m_rd_valid   (m_rd_valid),
        .m_wr_addr    (m_wr_addr),
        .m_wr_req     (m_wr_req),
        .m_wr_ack     (m_wr_ack),
        .dma_done_irq (dma_done_irq),
        .dma_busy     (dma_busy)
    );

    // Memory Models (Source and Destination RAMs)
    logic [31:0] src_ram [0:255];
    logic [31:0] dst_ram [0:255];

    // Bus Slave Responders
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            vif.m_rd_ack   <= 1'b0;
            vif.m_rd_valid <= 1'b0;
            vif.m_rd_data  <= 32'h0;
            vif.m_wr_ack   <= 1'b0;
        end else begin
            // Read Bus Responder
            if (vif.m_rd_req) begin
                vif.m_rd_ack   <= 1'b1;
                vif.m_rd_valid <= 1'b1;
                vif.m_rd_data  <= src_ram[vif.m_rd_addr[9:2]];
            end else begin
                vif.m_rd_ack   <= 1'b0;
                vif.m_rd_valid <= 1'b0;
            end

            // Write Bus Responder
            if (vif.m_wr_req) begin
                vif.m_wr_ack <= 1'b1;
                dst_ram[vif.m_wr_addr[9:2]] <= vif.m_wr_data;
            end else begin
                vif.m_wr_ack <= 1'b0;
            end
        end
    end

    // Task: Register Write
    task automatic reg_write(input logic [3:0] addr, input logic [31:0] data);
        @(vif.drv_cb);
        vif.drv_cb.ctrl_wr_en <= 1'b1;
        vif.drv_cb.ctrl_addr  <= addr;
        vif.drv_cb.ctrl_wdata <= data;
        @(vif.drv_cb);
        vif.drv_cb.ctrl_wr_en <= 1'b0;
    endtask

    // Main Stimulus Loop
    initial begin
        rst_n = 1'b0;
        vif.ctrl_wr_en = 1'b0;
        vif.ctrl_addr  = 4'h0;
        vif.ctrl_wdata = 32'h0;

        // Initialize RAMs
        for (int i = 0; i < 256; i++) begin
            src_ram[i] = 32'hA000_0000 + i;
            dst_ram[i] = 32'h0000_0000;
        end

        // Reset Sequence
        repeat (5) @(posedge clk);
        rst_n = 1'b1;
        repeat (2) @(posedge clk);

        $display("[TB] Starting DMA 4-Word Transfer Test...");
        reg_write(4'h0, 32'h0000_0010); // SRC ADDR = 0x10 (index 4)
        reg_write(4'h4, 32'h0000_0040); // DST ADDR = 0x40 (index 16)
        reg_write(4'h8, 32'd4);          // LEN = 4 words
        reg_write(4'hC, 32'h1);          // START = 1

        // Wait for IRQ
        wait (vif.dma_done_irq === 1'b1);
        @(posedge clk);
        $display("[TB] Transfer Complete IRQ detected.");

        // Verification Check
        for (int i = 0; i < 4; i++) begin
            if (dst_ram[16 + i] !== (32'hA000_0000 + 4 + i)) begin
                $error("[TB FAIL] Mismatch at index %0d: Expected 0x%08h, Got 0x%08h",
                       16 + i, (32'hA000_0000 + 4 + i), dst_ram[16 + i]);
            end else begin
                $display("[TB PASS] Word %0d matched: 0x%08h", i, dst_ram[16 + i]);
            end
        end

        #100;
        $display("[TB] All tests completed successfully.");
        $finish;
    end

endmodule : tb_top
