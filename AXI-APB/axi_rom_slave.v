module axi_rom_slave #(
    parameter ROM_WORDS = 1024   // 1024 words = 4 KB
)(
    input  wire        clk,
    input  wire        rst_n,

    // -----------------------------
    // AXI4-Lite SLAVE (READ ONLY)
    // -----------------------------
    input  wire [31:0] s_araddr,
    input  wire        s_arvalid,
    output reg         s_arready,

    output reg  [31:0] s_rdata,
    output reg         s_rvalid,
    input  wire        s_rready
);

    // -----------------------------
    // ROM storage
    // -----------------------------
    reg [31:0] rom [0:ROM_WORDS-1];

    // Load instructions
    initial begin
        $readmemh("src/rom.hex", rom);
    end

    // -----------------------------
    // Address latch
    // -----------------------------
    reg [31:0] addr_lat;

    // -----------------------------
    // Simple AXI read FSM
    // -----------------------------
    localparam IDLE = 1'b0;
    localparam RESP = 1'b1;

    reg state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state      <= IDLE;
            s_arready  <= 0;
            s_rvalid   <= 0;
            s_rdata    <= 0;
            addr_lat   <= 0;
        end else begin
            case (state)

                // -------------------------
                IDLE: begin
                // -------------------------
                    s_arready <= 1;
                    s_rvalid  <= 0;

                    if (s_arvalid) begin
                        addr_lat  <= s_araddr;
                        s_arready <= 0;
                        state     <= RESP;
                    end
                end

                // -------------------------
                RESP: begin
                // -------------------------
                    s_rdata  <= rom[addr_lat[11:2]]; // word aligned
                    s_rvalid <= 1;

                    if (s_rready) begin
                        s_rvalid <= 0;
                        state    <= IDLE;
                    end
                end

            endcase
        end
    end

endmodule
