module axi_interconnect (
    input  wire        clk,
    input  wire        rst_n,

    // =================================================
    // AXI SLAVE SIDE (from CPU / wrapper)
    // =================================================

    // Read address
    input  wire [31:0] s_araddr,
    input  wire        s_arvalid,
    output reg         s_arready,

    // Read data
    output reg  [31:0] s_rdata,
    output reg         s_rvalid,
    input  wire        s_rready,

    // Write address
    input  wire [31:0] s_awaddr,
    input  wire        s_awvalid,
    output reg         s_awready,

    // Write data
    input  wire [31:0] s_wdata,
    input  wire        s_wvalid,
    output reg         s_wready,

    // Write response
    output reg         s_bvalid,
    input  wire        s_bready,

    // =================================================
    // AXI MASTER SIDE → ROM
    // =================================================
    output reg  [31:0] m_rom_araddr,
    output reg         m_rom_arvalid,
    input  wire        m_rom_arready,

    input  wire [31:0] m_rom_rdata,
    input  wire        m_rom_rvalid,
    output reg         m_rom_rready,

    // =================================================
    // AXI MASTER SIDE → SRAM
    // =================================================
    output reg  [31:0] m_sram_araddr,
    output reg         m_sram_arvalid,
    input  wire        m_sram_arready,

    input  wire [31:0] m_sram_rdata,
    input  wire        m_sram_rvalid,
    output reg         m_sram_rready,

    output reg  [31:0] m_sram_awaddr,
    output reg         m_sram_awvalid,
    input  wire        m_sram_awready,

    output reg  [31:0] m_sram_wdata,
    output reg         m_sram_wvalid,
    input  wire        m_sram_wready,

    input  wire        m_sram_bvalid,
    output reg         m_sram_bready,

    // =================================================
    // AXI MASTER SIDE → AXI–APB BRIDGE
    // =================================================
    output reg  [31:0] m_apb_araddr,
    output reg         m_apb_arvalid,
    input  wire        m_apb_arready,

    input  wire [31:0] m_apb_rdata,
    input  wire        m_apb_rvalid,
    output reg         m_apb_rready,

    output reg  [31:0] m_apb_awaddr,
    output reg         m_apb_awvalid,
    input  wire        m_apb_awready,

    output reg  [31:0] m_apb_wdata,
    output reg         m_apb_wvalid,
    input  wire        m_apb_wready,

    input  wire        m_apb_bvalid,
    output reg         m_apb_bready
);

    // =================================================
    // Address regions (1 MB each)
    // =================================================
    localparam ROM_REGION  = 12'h000; // 0x0000_0000
    localparam SRAM_REGION = 12'h100; // 0x1000_0000
    localparam APB_REGION  = 12'h400; // 0x4000_0000

    // =================================================
    // Read target latch
    // =================================================
    localparam RD_ROM  = 2'd0;
    localparam RD_SRAM = 2'd1;
    localparam RD_APB  = 2'd2;

    reg [1:0] rd_target;

    // =================================================
    // Write target latch
    // =================================================
    localparam WR_SRAM = 2'd0;
    localparam WR_APB  = 2'd1;

    reg [1:0] wr_target;

    // =================================================
    // Latch READ destination on AR handshake
    // =================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_target <= RD_ROM;
        end else if (s_arvalid && s_arready) begin
            case (s_araddr[31:20])
                ROM_REGION:  rd_target <= RD_ROM;
                SRAM_REGION: rd_target <= RD_SRAM;
                APB_REGION:  rd_target <= RD_APB;
                default:     rd_target <= RD_ROM;
            endcase
        end
    end

    // =================================================
    // Latch WRITE destination on AW handshake
    // =================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_target <= WR_SRAM;
        end else if (s_awvalid && s_awready) begin
            case (s_awaddr[31:20])
                SRAM_REGION: wr_target <= WR_SRAM;
                APB_REGION:  wr_target <= WR_APB;
                default:     wr_target <= WR_SRAM;
            endcase
        end
    end

    // =================================================
    // ADDRESS PHASE ROUTING
    // =================================================
    always @(*) begin
        // Defaults
        s_arready = 0;
        s_awready = 0;
        s_wready  = 0;

        m_rom_arvalid  = 0;
        m_sram_arvalid = 0;
        m_apb_arvalid  = 0;

        m_rom_araddr  = s_araddr;
        m_sram_araddr = s_araddr;
        m_apb_araddr  = s_araddr;

        m_sram_awvalid = 0;
        m_apb_awvalid  = 0;

        m_sram_awaddr = s_awaddr;
        m_apb_awaddr  = s_awaddr;

        m_sram_wvalid = 0;
        m_apb_wvalid  = 0;

        m_sram_wdata = s_wdata;
        m_apb_wdata  = s_wdata;

        // READ ADDRESS
        if (s_arvalid) begin
            case (s_araddr[31:20])
                ROM_REGION: begin
                    m_rom_arvalid = 1;
                    s_arready     = m_rom_arready;
                end

                SRAM_REGION: begin
                    m_sram_arvalid = 1;
                    s_arready      = m_sram_arready;
                end

                APB_REGION: begin
                    m_apb_arvalid = 1;
                    s_arready     = m_apb_arready;
                end
            endcase
        end

        // WRITE ADDRESS + DATA
        if (s_awvalid && s_wvalid) begin
            case (s_awaddr[31:20])
                SRAM_REGION: begin
                    m_sram_awvalid = 1;
                    m_sram_wvalid  = 1;
                    s_awready      = m_sram_awready;
                    s_wready       = m_sram_wready;
                end

                APB_REGION: begin
                    m_apb_awvalid = 1;
                    m_apb_wvalid  = 1;
                    s_awready     = m_apb_awready;
                    s_wready      = m_apb_wready;
                end
            endcase
        end
    end

    // =================================================
    // READ DATA PHASE (independent of ARVALID)
    // =================================================
    always @(*) begin
        s_rvalid = 0;
        s_rdata  = 32'h0;

        m_rom_rready  = 0;
        m_sram_rready = 0;
        m_apb_rready  = 0;

        case (rd_target)
            RD_ROM: begin
                s_rvalid     = m_rom_rvalid;
                s_rdata      = m_rom_rdata;
                m_rom_rready = s_rready;
            end

            RD_SRAM: begin
                s_rvalid      = m_sram_rvalid;
                s_rdata       = m_sram_rdata;
                m_sram_rready = s_rready;
            end

            RD_APB: begin
                s_rvalid     = m_apb_rvalid;
                s_rdata      = m_apb_rdata;
                m_apb_rready = s_rready;
            end
        endcase
    end

    // =================================================
    // WRITE RESPONSE PHASE
    // =================================================
    always @(*) begin
        s_bvalid = 0;

        m_sram_bready = 0;
        m_apb_bready  = 0;

        case (wr_target)
            WR_SRAM: begin
                s_bvalid      = m_sram_bvalid;
                m_sram_bready = s_bready;
            end

            WR_APB: begin
                s_bvalid     = m_apb_bvalid;
                m_apb_bready = s_bready;
            end
        endcase
    end

endmodule
