module apb_top (
    input  wire        clk,
    input  wire        rst_n,

    // -----------------------------
    // CPU / TB interface
    // -----------------------------
    input  wire        req_valid,
    input  wire        req_write,
    input  wire [31:0] req_addr,
    input  wire [31:0] req_wdata,

    output wire        req_ready,
    output wire [31:0] req_rdata,
    output wire        req_error,

    // -----------------------------
    // GPIO external pins
    // -----------------------------
    input  wire [7:0]  gpio_in,
    output wire [7:0]  gpio_out,
    output wire [7:0]  gpio_dir
);

    // -------------------------------------------------
    // APB bus wires (master side)
    // -------------------------------------------------
    wire        PSEL;
    wire        PENABLE;
    wire        PWRITE;
    wire [31:0] PADDR;
    wire [31:0] PWDATA;
    wire [31:0] PRDATA;
    wire        PREADY;
    wire        PSLVERR;

    // -------------------------------------------------
    // Slave 0 (GPIO) wires
    // -------------------------------------------------
    wire        PSEL_S0;
    wire        PENABLE_S0;
    wire        PWRITE_S0;
    wire [31:0] PADDR_S0;
    wire [31:0] PWDATA_S0;
    wire [31:0] PRDATA_S0;
    wire        PREADY_S0;
    wire        PSLVERR_S0;

    // -------------------------------------------------
    // Slave 1 (ID + Counter) wires
    // -------------------------------------------------
    wire        PSEL_S1;
    wire        PENABLE_S1;
    wire        PWRITE_S1;
    wire [31:0] PADDR_S1;
    wire [31:0] PWDATA_S1;
    wire [31:0] PRDATA_S1;
    wire        PREADY_S1;
    wire        PSLVERR_S1;

    // -------------------------------------------------
    // APB MASTER
    // -------------------------------------------------
    apb_master u_apb_master (
        .clk       (clk),
        .rst_n     (rst_n),

        .req_valid (req_valid),
        .req_write (req_write),
        .req_addr  (req_addr),
        .req_wdata (req_wdata),

        .req_ready (req_ready),
        .req_rdata (req_rdata),
        .req_error (req_error),

        .PSEL      (PSEL),
        .PENABLE   (PENABLE),
        .PWRITE    (PWRITE),
        .PADDR     (PADDR),
        .PWDATA    (PWDATA),

        .PRDATA    (PRDATA),
        .PREADY    (PREADY),
        .PSLVERR   (PSLVERR)
    );

    // -------------------------------------------------
    // APB INTERCONNECT
    // -------------------------------------------------
    apb_interconnect u_apb_interconnect (
        .PSEL        (PSEL),
        .PENABLE     (PENABLE),
        .PWRITE      (PWRITE),
        .PADDR       (PADDR),
        .PWDATA      (PWDATA),

        .PRDATA      (PRDATA),
        .PREADY      (PREADY),
        .PSLVERR     (PSLVERR),

        .PSEL_S0     (PSEL_S0),
        .PENABLE_S0  (PENABLE_S0),
        .PWRITE_S0   (PWRITE_S0),
        .PADDR_S0    (PADDR_S0),
        .PWDATA_S0   (PWDATA_S0),
        .PRDATA_S0   (PRDATA_S0),
        .PREADY_S0   (PREADY_S0),
        .PSLVERR_S0  (PSLVERR_S0),

        .PSEL_S1     (PSEL_S1),
        .PENABLE_S1  (PENABLE_S1),
        .PWRITE_S1   (PWRITE_S1),
        .PADDR_S1    (PADDR_S1),
        .PWDATA_S1   (PWDATA_S1),
        .PRDATA_S1   (PRDATA_S1),
        .PREADY_S1   (PREADY_S1),
        .PSLVERR_S1  (PSLVERR_S1)
    );

    // -------------------------------------------------
    // SLAVE 0 : GPIO
    // -------------------------------------------------
    apb_gpio u_apb_gpio (
        .PCLK      (clk),
        .PRESETn   (rst_n),

        .PSEL      (PSEL_S0),
        .PENABLE   (PENABLE_S0),
        .PWRITE    (PWRITE_S0),
        .PADDR     (PADDR_S0),
        .PWDATA    (PWDATA_S0),

        .PRDATA    (PRDATA_S0),
        .PREADY    (PREADY_S0),
        .PSLVERR   (PSLVERR_S0),

        .gpio_in   (gpio_in),
        .gpio_out  (gpio_out),
        .gpio_dir  (gpio_dir)
    );

    // -------------------------------------------------
    // SLAVE 1 : ID + Counter
    // -------------------------------------------------
    apb_id_counter u_apb_id_counter (
        .PCLK      (clk),
        .PRESETn   (rst_n),

        .PSEL      (PSEL_S1),
        .PENABLE   (PENABLE_S1),
        .PWRITE    (PWRITE_S1),
        .PADDR     (PADDR_S1),
        .PWDATA    (PWDATA_S1),

        .PRDATA    (PRDATA_S1),
        .PREADY    (PREADY_S1),
        .PSLVERR   (PSLVERR_S1)
    );

endmodule
