`timescale 1ns / 1ps

module dma_engine #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
)(
    input  wire                   clk,
    input  wire                   rst_n,

    // =========================================================
    // Control / Register Interface (Worker)
    // =========================================================
    input  wire                   ctrl_wr_en,
    input  wire [3:0]             ctrl_addr,      // 0x0: SRC, 0x4: DST, 0x8: LEN, 0xC: CTRL
    input  wire [DATA_WIDTH-1:0]  ctrl_wdata,
    output reg  [DATA_WIDTH-1:0]  ctrl_rdata,

    // =========================================================
    // Master Read Interface (Source Memory Bus)
    // =========================================================
    output reg  [ADDR_WIDTH-1:0]  m_rd_addr,
    output reg                    m_rd_req,
    input  wire                   m_rd_ack,
    input  wire [DATA_WIDTH-1:0]  m_rd_data,
    input  wire                   m_rd_valid,

    // =========================================================
    // Master Write Interface (Destination Memory Bus)
    // =========================================================
    output reg  [ADDR_WIDTH-1:0]  m_wr_addr,
    output reg  [DATA_WIDTH-1:0]  m_wr_data,
    output reg                    m_wr_req,
    input  wire                   m_wr_ack,

    // =========================================================
    // Interrupt / Status Output
    // =========================================================
    output reg                    dma_done_irq,
    output wire                   dma_busy
);

    // ---------------------------------------------------------
    // Register Map Offsets
    // ---------------------------------------------------------
    localparam REG_SRC_ADDR = 4'h0;
    localparam REG_DST_ADDR = 4'h4;
    localparam REG_LEN      = 4'h8; // Transfer length in 32-bit words
    localparam REG_CTRL     = 4'hC; // Bit 0: Start, Bit 1: Soft Reset

    // ---------------------------------------------------------
    // Internal Registers
    // ---------------------------------------------------------
    reg [ADDR_WIDTH-1:0] reg_src_addr;
    reg [ADDR_WIDTH-1:0] reg_dst_addr;
    reg [DATA_WIDTH-1:0] reg_len;
    reg                  reg_start;

    // Working Registers / Counters
    reg [ADDR_WIDTH-1:0] curr_src_addr;
    reg [ADDR_WIDTH-1:0] curr_dst_addr;
    reg [DATA_WIDTH-1:0] words_left;
    reg [DATA_WIDTH-1:0] data_buffer;

    // ---------------------------------------------------------
    // FSM States
    // ---------------------------------------------------------
    localparam [2:0] IDLE       = 3'b000,
                     LOAD_REQ   = 3'b001,
                     LOAD_WAIT  = 3'b010,
                     STORE_REQ  = 3'b011,
                     STORE_WAIT = 3'b100,
                     DONE       = 3'b101;

    reg [2:0] state, next_state;

    assign dma_busy = (state != IDLE);

    // ---------------------------------------------------------
    // Host Register Write / Read Logic
    // ---------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_src_addr <= {ADDR_WIDTH{1'b0}};
            reg_dst_addr <= {ADDR_WIDTH{1'b0}};
            reg_len      <= {DATA_WIDTH{1'b0}};
            reg_start    <= 1'b0;
        end else begin
            reg_start <= 1'b0; // Auto-clearing start strobe
            if (ctrl_wr_en) begin
                case (ctrl_addr)
                    REG_SRC_ADDR: reg_src_addr <= ctrl_wdata;
                    REG_DST_ADDR: reg_dst_addr <= ctrl_wdata;
                    REG_LEN:      reg_len      <= ctrl_wdata;
                    REG_CTRL: begin
                        if (ctrl_wdata[0]) reg_start <= 1'b1;
                    end
                    default: ;
                endcase
            end
        end
    end

    always @(*) begin
        case (ctrl_addr)
            REG_SRC_ADDR: ctrl_rdata = reg_src_addr;
            REG_DST_ADDR: ctrl_rdata = reg_dst_addr;
            REG_LEN:      ctrl_rdata = reg_len;
            REG_CTRL:     ctrl_rdata = {{(DATA_WIDTH-2){1'b0}}, dma_busy, dma_done_irq};
            default:      ctrl_rdata = {DATA_WIDTH{1'b0}};
        endcase
    end

    // ---------------------------------------------------------
    // FSM State Transition
    // ---------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (reg_start && (reg_len != 0))
                    next_state = LOAD_REQ;
            end

            LOAD_REQ: begin
                if (m_rd_ack)
                    next_state = LOAD_WAIT;
            end

            LOAD_WAIT: begin
                if (m_rd_valid)
                    next_state = STORE_REQ;
            end

            STORE_REQ: begin
                if (m_wr_ack)
                    next_state = STORE_WAIT;
            end

            STORE_WAIT: begin
                if (words_left == 1)
                    next_state = DONE;
                else
                    next_state = LOAD_REQ;
            end

            DONE: begin
                next_state = IDLE;
            end

            default: next_state = IDLE;
        endcase
    end

    // ---------------------------------------------------------
    // Datapath & Transfer Control Logic
    // ---------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m_rd_addr     <= {ADDR_WIDTH{1'b0}};
            m_rd_req      <= 1'b0;
            m_wr_addr     <= {ADDR_WIDTH{1'b0}};
            m_wr_data     <= {DATA_WIDTH{1'b0}};
            m_wr_req      <= 1'b0;
            curr_src_addr <= {ADDR_WIDTH{1'b0}};
            curr_dst_addr <= {ADDR_WIDTH{1'b0}};
            words_left    <= {DATA_WIDTH{1'b0}};
            data_buffer   <= {DATA_WIDTH{1'b0}};
            dma_done_irq  <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    dma_done_irq <= 1'b0;
                    if (reg_start && (reg_len != 0)) begin
                        curr_src_addr <= reg_src_addr;
                        curr_dst_addr <= reg_dst_addr;
                        words_left    <= reg_len;
                    end
                end

                LOAD_REQ: begin
                    m_rd_addr <= curr_src_addr;
                    m_rd_req  <= 1'b1;
                    if (m_rd_ack) begin
                        m_rd_req <= 1'b0;
                    end
                end

                LOAD_WAIT: begin
                    if (m_rd_valid) begin
                        data_buffer   <= m_rd_data;
                        curr_src_addr <= curr_src_addr + 4; // Word-aligned (+4 bytes)
                    end
                end

                STORE_REQ: begin
                    m_wr_addr <= curr_dst_addr;
                    m_wr_data <= data_buffer;
                    m_wr_req  <= 1'b1;
                    if (m_wr_ack) begin
                        m_wr_req <= 1'b0;
                    end
                end

                STORE_WAIT: begin
                    curr_dst_addr <= curr_dst_addr + 4;
                    words_left    <= words_left - 1;
                end

                DONE: begin
                    dma_done_irq <= 1'b1;
                end

                default: ;
            endcase
        end
    end

endmodule
