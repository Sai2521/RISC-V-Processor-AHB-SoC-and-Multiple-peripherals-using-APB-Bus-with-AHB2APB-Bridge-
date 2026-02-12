module axi_sram_slave #(
    parameter SRAM_WORDS = 4096   // 4096 words = 16 KB
)(
    input  wire        clk,
    input  wire        rst_n,

    // -----------------------------
    // AXI4-Lite SLAVE
    // -----------------------------

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
    input  wire        s_bready
);

    // -----------------------------
    // SRAM storage
    // -----------------------------
    reg [31:0] sram [0:SRAM_WORDS-1];

    // -----------------------------
    // Latches
    // -----------------------------
    reg [31:0] addr_lat;
    reg [31:0] wdata_lat;
    reg        is_write;

    // -----------------------------
    // FSM
    // -----------------------------
    localparam IDLE = 2'b00;
    localparam READ_RESP = 2'b01;
    localparam WRITE_RESP = 2'b10;

    reg [1:0] state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state      <= IDLE;
            s_arready  <= 0;
            s_awready  <= 0;
            s_wready   <= 0;
            s_rvalid   <= 0;
            s_bvalid   <= 0;
            s_rdata    <= 0;
        end else begin
            // defaults
            s_arready <= 0;
            s_awready <= 0;
            s_wready  <= 0;

            case (state)

                // -------------------------
                IDLE: begin
                // -------------------------
                    s_rvalid <= 0;
                    s_bvalid <= 0;

                    // READ
                    if (s_arvalid) begin
                        s_arready <= 1;
                        addr_lat  <= s_araddr;
                        is_write  <= 0;
                        state     <= READ_RESP;
                    end

                    // WRITE
                    else if (s_awvalid && s_wvalid) begin
                        s_awready <= 1;
                        s_wready  <= 1;
                        addr_lat  <= s_awaddr;
                        wdata_lat <= s_wdata;
                        is_write  <= 1;

                        // perform write
                        sram[s_awaddr[13:2]] <= s_wdata;

                        state <= WRITE_RESP;
                    end
                end

                // -------------------------
                READ_RESP: begin
                // -------------------------
                    s_rdata  <= sram[addr_lat[13:2]];
                    s_rvalid <= 1;

                    if (s_rready) begin
                        s_rvalid <= 0;
                        state    <= IDLE;
                    end
                end

                // -------------------------
                WRITE_RESP: begin
                // -------------------------
                    s_bvalid <= 1;

                    if (s_bready) begin
                        s_bvalid <= 0;
                        state    <= IDLE;
                    end
                end

            endcase
        end
    end

endmodule
