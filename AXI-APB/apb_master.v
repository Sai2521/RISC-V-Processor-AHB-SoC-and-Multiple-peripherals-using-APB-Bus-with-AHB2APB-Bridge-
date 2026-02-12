module apb_master (
    input  wire        clk,
    input  wire        rst_n,

    // -----------------------------
    // CPU / AXI-like request side
    // -----------------------------
    input  wire        req_valid,
    input  wire        req_write,
    input  wire [31:0] req_addr,
    input  wire [31:0] req_wdata,

    output reg         req_ready,
    output reg  [31:0] req_rdata,
    output reg         req_error,

    // -----------------------------
    // APB bus side
    // -----------------------------
    output reg         PSEL,
    output reg         PENABLE,
    output reg         PWRITE,
    output reg  [31:0] PADDR,
    output reg  [31:0] PWDATA,

    input  wire [31:0] PRDATA,
    input  wire        PREADY,
    input  wire        PSLVERR
);


    localparam ST_IDLE   = 2'b00;
    localparam ST_SETUP  = 2'b01;
    localparam ST_ACCESS = 2'b10;

    reg [1:0] state, next_state;

    reg [31:0] addr_lat;
    reg [31:0] wdata_lat;
    reg        write_lat;
    
    // -------------------------------------------------
    // FSM state register
    // -------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= ST_IDLE;
            req_ready <= 1'b0;
            req_rdata <= 32'h0;
            req_error <= 1'b0;
        end else
            state <= next_state;
    end

    always @(*) begin
        next_state = state;

        case (state)
            ST_IDLE: begin
                if (req_valid)
                    next_state = ST_SETUP;
                    PENABLE = 1'b0;
                    PSEL = 1'b0;
            end

            ST_SETUP: begin
                next_state = ST_ACCESS;
            end

            ST_ACCESS: begin
                if (PREADY)
                    next_state = ST_IDLE;
            end
        endcase
    end

    always @(*) begin

        case(state)
            ST_IDLE: begin
                addr_lat <= req_addr;
                wdata_lat <= req_wdata;
                write_lat <= req_write;
                req_ready <= 1'b0;
            end

            ST_SETUP: begin
                PADDR <= addr_lat;
                PWDATA <= wdata_lat;
                PWRITE <= write_lat;

                PSEL <= 1'b1;
            end

            ST_ACCESS: begin
                PENABLE <= 1'b1;
                if(PREADY) begin
                    req_rdata <= PRDATA;
                    req_error <= PSLVERR;
                    req_ready <= PREADY;
                end
            end

        endcase
    end

endmodule