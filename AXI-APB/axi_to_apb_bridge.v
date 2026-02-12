module axi_to_apb_bridge (
    input  wire        clk,
    input  wire        rst_n,

    // =================================================
    // AXI4-Lite SLAVE INTERFACE
    // =================================================

    // Read address channel
    input  wire [31:0] s_araddr,
    input  wire        s_arvalid,
    output reg         s_arready,

    // Read data channel
    output reg  [31:0] s_rdata,
    output reg         s_rvalid,
    input  wire        s_rready,

    // Write address channel
    input  wire [31:0] s_awaddr,
    input  wire        s_awvalid,
    output reg         s_awready,

    // Write data channel
    input  wire [31:0] s_wdata,
    input  wire        s_wvalid,
    output reg         s_wready,

    // Write response channel
    output reg         s_bvalid,
    input  wire        s_bready,

    // =================================================
    // APB MASTER → APB INTERCONNECT
    // =================================================
    output reg         PSEL,
    output reg         PENABLE,
    output reg         PWRITE,
    output reg  [31:0] PADDR,
    output reg  [31:0] PWDATA,

    input  wire [31:0] PRDATA,
    input  wire        PREADY,
    input  wire        PSLVERR
);

    // =================================================
    // INTERNAL REGISTERS
    // =================================================
    reg [31:0] addr_lat;
    reg [31:0] wdata_lat;
    reg        write_lat;
    // reg [31:0] rdata_lat;


    // =================================================
    // FSM STATES
    // =================================================
    localparam ST_IDLE   = 2'b00;
    localparam ST_SETUP  = 2'b01;
    localparam ST_ACCESS = 2'b10;
    localparam ST_RESP   = 2'b11;

    reg [1:0] state, next_state;

    // =================================================
    // STATE REGISTER
    // =================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= ST_IDLE;
        else
            state <= next_state;
    end

    // =================================================
    // NEXT STATE LOGIC
    // =================================================
    always @(*) begin
        next_state = state;

        case (state)
            ST_IDLE: begin
                if (s_arvalid || (s_awvalid && s_wvalid))
                    next_state = ST_SETUP;
            end

            ST_SETUP: begin
                next_state = ST_ACCESS;
            end

            ST_ACCESS: begin
                if (PREADY)
                    next_state = ST_RESP;
            end

            ST_RESP: begin
                if ((write_lat && s_bready) ||
                   (!write_lat && s_rready))
                    next_state = ST_IDLE;
            end
        endcase
    end

    // =================================================
    // OUTPUT & DATA PATH
    // =================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // AXI
            s_arready <= 0;
            s_awready <= 0;
            s_wready  <= 0;
            s_rvalid  <= 0;
            s_bvalid  <= 0;
            s_rdata   <= 0;

            // APB
            PSEL    <= 0;
            PENABLE <= 0;
            PWRITE  <= 0;
            PADDR   <= 0;
            PWDATA  <= 0;

            // Internal
            addr_lat  <= 0;
            wdata_lat <= 0;
            write_lat <= 0;
        end
        else begin
            // defaults
            s_arready <= 0;
            s_awready <= 0;
            s_wready  <= 0;
            s_rvalid  <= 0;
            s_bvalid  <= 0;

            case (state)

                // ---------------------------------
                ST_IDLE: begin
                // ---------------------------------
                    PSEL    <= 0;
                    PENABLE <= 0;

                    if (s_arvalid) begin
                        s_arready <= 1;
                        addr_lat  <= s_araddr;
                        write_lat <= 0;
                    end
                    else if (s_awvalid && s_wvalid) begin
                        s_awready <= 1;
                        s_wready  <= 1;
                        addr_lat  <= s_awaddr;
                        wdata_lat <= s_wdata;
                        write_lat <= 1;
                    end
                end

                // ---------------------------------
                ST_SETUP: begin
                // ---------------------------------
                    PSEL   <= 1;
                    PADDR  <= addr_lat;
                    PWRITE <= write_lat;
                    PWDATA <= wdata_lat;
                    s_rdata <= PRDATA;
                end

                // ---------------------------------
                ST_ACCESS: begin
                // ---------------------------------
                    PENABLE <= 1;

                    if (PREADY && !write_lat) begin
                        // s_rvalid <= 1;
                        // s_rdata <= PRDATA;
                        // rdata_lat <= PRDATA;
                    end
                end

                // ---------------------------------
                ST_RESP: begin
                // ---------------------------------
                    PSEL    <= 0;
                    PENABLE <= 0;

                    if (write_lat)
                        s_bvalid <= 1;
                    else
                        s_rdata <= PRDATA;
                        s_rvalid <= 1;
                        // s_rvalid <= 1;
                        // s_rdata <= rdata_lat;
                end

            endcase
        end
    end

endmodule
