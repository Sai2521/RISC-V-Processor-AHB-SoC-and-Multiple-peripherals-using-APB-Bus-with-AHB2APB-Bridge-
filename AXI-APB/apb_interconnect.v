module apb_interconnect (
    // -------------------------------------------------
    // From APB master
    // -------------------------------------------------
    input  wire        PSEL,
    input  wire        PENABLE,
    input  wire        PWRITE,
    input  wire [31:0] PADDR,
    input  wire [31:0] PWDATA,

    output wire [31:0] PRDATA,
    output wire        PREADY,
    output wire        PSLVERR,

    // -------------------------------------------------
    // To APB Slave 0
    // -------------------------------------------------
    output wire        PSEL_S0,
    output wire        PENABLE_S0,
    output wire        PWRITE_S0,
    output wire [31:0] PADDR_S0,
    output wire [31:0] PWDATA_S0,

    input  wire [31:0] PRDATA_S0,
    input  wire        PREADY_S0,
    input  wire        PSLVERR_S0,

    // -------------------------------------------------
    // To APB Slave 1
    // -------------------------------------------------
    output wire        PSEL_S1,
    output wire        PENABLE_S1,
    output wire        PWRITE_S1,
    output wire [31:0] PADDR_S1,
    output wire [31:0] PWDATA_S1,

    input  wire [31:0] PRDATA_S1,
    input  wire        PREADY_S1,
    input  wire        PSLVERR_S1
);

    // -------------------------------------------------
    // Address decode
    // 0x0000_0000 – 0x0000_0FFF → Slave 0
    // 0x0000_1000 – 0x0000_1FFF → Slave 1
    // -------------------------------------------------
    wire sel_s0;
    wire sel_s1;

    assign sel_s0 = (PADDR[12] == 1'b0);
    assign sel_s1 = (PADDR[12] == 1'b1);


    // -------------------------------------------------
    // PSEL generation
    // -------------------------------------------------
    assign PSEL_S0 = PSEL & sel_s0;
    assign PSEL_S1 = PSEL & sel_s1;

    // -------------------------------------------------
    // Pass-through APB signals
    // -------------------------------------------------
    assign PENABLE_S0 = PENABLE & PSEL_S0;
    assign PWRITE_S0  = PWRITE;
    assign PADDR_S0   = PADDR;
    assign PWDATA_S0  = PWDATA;

    assign PENABLE_S1 = PENABLE & PSEL_S1;
    assign PWRITE_S1  = PWRITE;
    assign PADDR_S1   = PADDR;
    assign PWDATA_S1  = PWDATA;

    // -------------------------------------------------
    // Response mux
    // -------------------------------------------------
    assign PRDATA = PSEL_S0 ? PRDATA_S0 :
                    PSEL_S1 ? PRDATA_S1 :
                    32'h00000000;

    assign PREADY = PSEL_S0 ? PREADY_S0 :
                    PSEL_S1 ? PREADY_S1 :
                    1'b0;

    assign PSLVERR = PSEL_S0 ? PSLVERR_S0 :
                    PSEL_S1 ? PSLVERR_S1 :
                    1'b0;

endmodule
