module top_soc (
    input  wire clk,
    input  wire rst_n
);

    // =================================================
    // CPU <-> Wrapper
    // =================================================
    wire        if_req;
    wire [31:0] if_pc;
    wire [31:0] if_instr;
    wire        if_ready;

    wire        mem_req;
    wire        mem_write;
    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire [31:0] mem_rdata;
    wire        mem_ready;

    wire        stall;

    // =================================================
    // Wrapper <-> AXI interconnect
    // =================================================
    wire [31:0] araddr;
    wire        arvalid;
    wire        arready;

    wire [31:0] rdata;
    wire        rvalid;
    wire        rready;

    wire [31:0] awaddr;
    wire        awvalid;
    wire        awready;

    wire [31:0] wdata;
    wire        wvalid;
    wire        wready;

    wire        bvalid;
    wire        bready;

    // =================================================
    // AXI interconnect <-> ROM
    // =================================================
    wire [31:0] rom_araddr;
    wire        rom_arvalid;
    wire        rom_arready;
    wire [31:0] rom_rdata;
    wire        rom_rvalid;
    wire        rom_rready;

    // =================================================
    // AXI interconnect <-> SRAM
    // =================================================
    wire [31:0] sram_araddr;
    wire        sram_arvalid;
    wire        sram_arready;
    wire [31:0] sram_rdata;
    wire        sram_rvalid;
    wire        sram_rready;

    wire [31:0] sram_awaddr;
    wire        sram_awvalid;
    wire        sram_awready;
    wire [31:0] sram_wdata;
    wire        sram_wvalid;
    wire        sram_wready;
    wire        sram_bvalid;
    wire        sram_bready;

    // =================================================
    // AXI interconnect <-> AXI–APB bridge
    // =================================================
    wire [31:0] apb_araddr;
    wire        apb_arvalid;
    wire        apb_arready;
    wire [31:0] apb_rdata;
    wire        apb_rvalid;
    wire        apb_rready;

    wire [31:0] apb_awaddr;
    wire        apb_awvalid;
    wire        apb_awready;
    wire [31:0] apb_wdata;
    wire        apb_wvalid;
    wire        apb_wready;
    wire        apb_bvalid;
    wire        apb_bready;

    // =================================================
    // APB wires
    // =================================================
    wire        PSEL;
    wire        PENABLE;
    wire        PWRITE;
    wire [31:0] PADDR;
    wire [31:0] PWDATA;
    wire [31:0] PRDATA;
    wire        PREADY;
    wire        PSLVERR;

    wire        PSEL_S0, PENABLE_S0, PWRITE_S0;
    wire [31:0] PADDR_S0, PWDATA_S0, PRDATA_S0;
    wire        PREADY_S0, PSLVERR_S0;

    wire        PSEL_S1, PENABLE_S1, PWRITE_S1;
    wire [31:0] PADDR_S1, PWDATA_S1, PRDATA_S1;
    wire        PREADY_S1, PSLVERR_S1;

    // =================================================
    // CPU CORE
    // =================================================
    top cpu (
        .clk        (clk),
        .rst        (~rst_n),

        .if_req     (if_req),
        .if_pc      (if_pc),
        .if_instr   (if_instr),
        .if_ready   (if_ready),

        .mem_req    (mem_req),
        .mem_write  (mem_write),
        .mem_addr   (mem_addr),
        .mem_wdata  (mem_wdata),
        .mem_rdata  (mem_rdata),
        .mem_ready  (mem_ready),

        .stall      (stall)
    );

    // =================================================
    // CPU AXI WRAPPER
    // =================================================
    cpu_axi_wrapper wrapper (
        .clk        (clk),
        .rst_n      (rst_n),

        .if_req     (if_req),
        .if_pc      (if_pc),
        .if_instr   (if_instr),
        .if_ready   (if_ready),

        .mem_req    (mem_req),
        .mem_write  (mem_write),
        .mem_addr   (mem_addr),
        .mem_wdata  (mem_wdata),
        .mem_rdata  (mem_rdata),
        .mem_ready  (mem_ready),

        .stall      (stall),

        .m_araddr   (araddr),
        .m_arvalid  (arvalid),
        .m_arready  (arready),

        .m_rdata    (rdata),
        .m_rvalid   (rvalid),
        .m_rready   (rready),

        .m_awaddr   (awaddr),
        .m_awvalid  (awvalid),
        .m_awready  (awready),

        .m_wdata    (wdata),
        .m_wvalid   (wvalid),
        .m_wready   (wready),

        .m_bvalid   (bvalid),
        .m_bready   (bready)
    );

    // =================================================
    // AXI INTERCONNECT
    // =================================================
    axi_interconnect axi_ic (
        .clk        (clk),
        .rst_n      (rst_n),

        .s_araddr   (araddr),
        .s_arvalid  (arvalid),
        .s_arready  (arready),

        .s_rdata    (rdata),
        .s_rvalid   (rvalid),
        .s_rready   (rready),

        .s_awaddr   (awaddr),
        .s_awvalid  (awvalid),
        .s_awready  (awready),

        .s_wdata    (wdata),
        .s_wvalid   (wvalid),
        .s_wready   (wready),

        .s_bvalid   (bvalid),
        .s_bready   (bready),

        // ROM
        .m_rom_araddr  (rom_araddr),
        .m_rom_arvalid (rom_arvalid),
        .m_rom_arready (rom_arready),
        .m_rom_rdata   (rom_rdata),
        .m_rom_rvalid  (rom_rvalid),
        .m_rom_rready  (rom_rready),

        // SRAM
        .m_sram_araddr (sram_araddr),
        .m_sram_arvalid(sram_arvalid),
        .m_sram_arready(sram_arready),
        .m_sram_rdata  (sram_rdata),
        .m_sram_rvalid (sram_rvalid),
        .m_sram_rready (sram_rready),

        .m_sram_awaddr (sram_awaddr),
        .m_sram_awvalid(sram_awvalid),
        .m_sram_awready(sram_awready),
        .m_sram_wdata  (sram_wdata),
        .m_sram_wvalid (sram_wvalid),
        .m_sram_wready (sram_wready),
        .m_sram_bvalid (sram_bvalid),
        .m_sram_bready (sram_bready),

        // APB
        .m_apb_araddr  (apb_araddr),
        .m_apb_arvalid (apb_arvalid),
        .m_apb_arready (apb_arready),
        .m_apb_rdata   (apb_rdata),
        .m_apb_rvalid  (apb_rvalid),
        .m_apb_rready  (apb_rready),

        .m_apb_awaddr  (apb_awaddr),
        .m_apb_awvalid (apb_awvalid),
        .m_apb_awready (apb_awready),
        .m_apb_wdata   (apb_wdata),
        .m_apb_wvalid  (apb_wvalid),
        .m_apb_wready  (apb_wready),

        .m_apb_bvalid  (apb_bvalid),
        .m_apb_bready  (apb_bready)
    );

    // =================================================
    // AXI ROM
    // =================================================
    axi_rom_slave rom (
        .clk        (clk),
        .rst_n      (rst_n),
        .s_araddr   (rom_araddr),
        .s_arvalid  (rom_arvalid),
        .s_arready  (rom_arready),
        .s_rdata    (rom_rdata),
        .s_rvalid   (rom_rvalid),
        .s_rready   (rom_rready)
    );

    // =================================================
    // AXI SRAM
    // =================================================
    axi_sram_slave sram (
        .clk        (clk),
        .rst_n      (rst_n),

        .s_araddr   (sram_araddr),
        .s_arvalid  (sram_arvalid),
        .s_arready  (sram_arready),
        .s_rdata    (sram_rdata),
        .s_rvalid   (sram_rvalid),
        .s_rready   (sram_rready),

        .s_awaddr   (sram_awaddr),
        .s_awvalid  (sram_awvalid),
        .s_awready  (sram_awready),

        .s_wdata    (sram_wdata),
        .s_wvalid   (sram_wvalid),
        .s_wready   (sram_wready),

        .s_bvalid   (sram_bvalid),
        .s_bready   (sram_bready)
    );

    // =================================================
    // AXI → APB BRIDGE
    // =================================================
    axi_to_apb_bridge bridge (
        .clk        (clk),
        .rst_n      (rst_n),

        .s_araddr   (apb_araddr),
        .s_arvalid  (apb_arvalid),
        .s_arready  (apb_arready),

        .s_rdata    (apb_rdata),
        .s_rvalid   (apb_rvalid),
        .s_rready   (apb_rready),

        .s_awaddr   (apb_awaddr),
        .s_awvalid  (apb_awvalid),
        .s_awready  (apb_awready),

        .s_wdata    (apb_wdata),
        .s_wvalid   (apb_wvalid),
        .s_wready   (apb_wready),

        .s_bvalid   (apb_bvalid),
        .s_bready   (apb_bready),

        .PSEL       (PSEL),
        .PENABLE    (PENABLE),
        .PWRITE     (PWRITE),
        .PADDR      (PADDR),
        .PWDATA     (PWDATA),
        .PRDATA     (PRDATA),
        .PREADY     (PREADY),
        .PSLVERR    (PSLVERR)
    );

    // =================================================
    // APB INTERCONNECT
    // =================================================
    apb_interconnect apb_ic (
        .PSEL       (PSEL),
        .PENABLE    (PENABLE),
        .PWRITE     (PWRITE),
        .PADDR      (PADDR),
        .PWDATA     (PWDATA),

        .PRDATA     (PRDATA),
        .PREADY     (PREADY),
        .PSLVERR    (PSLVERR),

        .PSEL_S0    (PSEL_S0),
        .PENABLE_S0 (PENABLE_S0),
        .PWRITE_S0  (PWRITE_S0),
        .PADDR_S0   (PADDR_S0),
        .PWDATA_S0  (PWDATA_S0),
        .PRDATA_S0  (PRDATA_S0),
        .PREADY_S0  (PREADY_S0),
        .PSLVERR_S0 (PSLVERR_S0),

        .PSEL_S1    (PSEL_S1),
        .PENABLE_S1 (PENABLE_S1),
        .PWRITE_S1  (PWRITE_S1),
        .PADDR_S1   (PADDR_S1),
        .PWDATA_S1  (PWDATA_S1),
        .PRDATA_S1  (PRDATA_S1),
        .PREADY_S1  (PREADY_S1),
        .PSLVERR_S1 (PSLVERR_S1)
    );

    // =================================================
    // APB SLAVES
    // =================================================
    apb_gpio gpio (
        .PCLK       (clk),
        .PRESETn    (rst_n),
        .PSEL       (PSEL_S0),
        .PENABLE    (PENABLE_S0),
        .PWRITE     (PWRITE_S0),
        .PADDR      (PADDR_S0),
        .PWDATA     (PWDATA_S0),
        .PRDATA     (PRDATA_S0),
        .PREADY     (PREADY_S0),
        .PSLVERR    (PSLVERR_S0),
        .gpio_in    (8'b0),
        .gpio_out   (),
        .gpio_dir   ()
    );

    apb_id_counter idc (
        .PCLK       (clk),
        .PRESETn    (rst_n),
        .PSEL       (PSEL_S1),
        .PENABLE    (PENABLE_S1),
        .PWRITE     (PWRITE_S1),
        .PADDR      (PADDR_S1),
        .PWDATA     (PWDATA_S1),
        .PRDATA     (PRDATA_S1),
        .PREADY     (PREADY_S1),
        .PSLVERR    (PSLVERR_S1)
    );

endmodule
