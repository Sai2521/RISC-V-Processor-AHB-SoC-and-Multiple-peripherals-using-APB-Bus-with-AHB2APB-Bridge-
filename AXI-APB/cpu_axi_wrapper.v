module cpu_axi_wrapper (
    input  wire        clk,
    input  wire        rst_n,

    // =============================
    // CPU SIDE
    // =============================
    input  wire        if_req,
    input  wire [31:0] if_pc,
    output reg  [31:0] if_instr,
    output reg         if_ready,

    input  wire        mem_req,
    input  wire        mem_write,
    input  wire [31:0] mem_addr,
    input  wire [31:0] mem_wdata,
    output reg  [31:0] mem_rdata,
    output reg         mem_ready,

    // Stall CPU
    output wire        stall,

    // =============================
    // AXI MASTER INTERFACE
    // =============================
    output reg  [31:0] m_araddr,
    output reg         m_arvalid,
    input  wire        m_arready,

    input  wire [31:0] m_rdata,
    input  wire        m_rvalid,
    output reg         m_rready,

    output reg  [31:0] m_awaddr,
    output reg         m_awvalid,
    input  wire        m_awready,

    output reg  [31:0] m_wdata,
    output reg         m_wvalid,
    input  wire        m_wready,

    input  wire        m_bvalid,
    output reg         m_bready
);

    // =============================
    // FSM STATES
    // =============================
    localparam IDLE     = 4'd0;
    localparam IF_AR    = 4'd1;
    localparam IF_R     = 4'd2;
    localparam DECODE   = 4'd3;
    localparam MEM_AR   = 4'd4;
    localparam MEM_R    = 4'd5;
    localparam MEM_AW_W = 4'd6;
    localparam MEM_B    = 4'd7;
    localparam MEM_WAIT = 4'd8;

    reg [3:0] state;

    // =============================
    // INSTRUCTION-ACTIVE FLAG
    // =============================
    reg instr_active;
    assign stall = instr_active;

    // =============================
    // REQUEST LATCHES
    // =============================
    reg        req_is_write;
    reg [31:0] req_addr;
    reg [31:0] req_wdata;

    // =============================
    // STATE MACHINE
    // =============================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state        <= IDLE;
            instr_active <= 1'b0;

            if_ready  <= 1'b0;
            mem_ready <= 1'b0;

            m_arvalid <= 1'b0;
            m_rready  <= 1'b0;
            m_awvalid <= 1'b0;
            m_wvalid  <= 1'b0;
            m_bready  <= 1'b0;
        end
        else begin
            // -------------------------
            // defaults
            // -------------------------
            if_ready  <= 1'b0;
            mem_ready <= 1'b0;

            m_arvalid <= 1'b0;
            m_rready  <= 1'b0;
            m_awvalid <= 1'b0;
            m_wvalid  <= 1'b0;
            m_bready  <= 1'b0;

            case (state)

                // =========================
                // IDLE (no instruction active)
                // =========================
                IDLE: begin
                    instr_active <= 1'b0;

                    if (if_req) begin
                        instr_active <= 1'b1;
                        req_addr     <= if_pc;
                        state        <= IF_AR;
                    end
                end

                // =========================
                // Instruction Fetch Address
                // =========================
                IF_AR: begin
                    m_araddr  <= req_addr;
                    m_arvalid <= 1'b1;

                    if (m_arready)
                        state <= IF_R;
                end

                // =========================
                // Instruction Fetch Data
                // =========================
                IF_R: begin
                    m_rready <= 1'b1;

                    if (m_rvalid) begin
                        if_instr <= m_rdata;
                        if_ready <= 1'b1;
                        state    <= DECODE;
                    end
                end

                // =========================
                // DECODE (observe mem_req)
                // =========================
                DECODE: begin
                    if (mem_req) begin
                        req_addr     <= mem_addr;
                        req_wdata    <= mem_wdata;
                        req_is_write <= mem_write;

                        if (mem_write)
                            state <= MEM_AW_W;
                        else
                            state <= MEM_AR;
                    end
                    else begin
                        // // ALU / LUI / ADDI commit here
                        // instr_active <= 1'b0;
                        state <= MEM_WAIT;
                    end
                end

                // =========================
                // Data Read Address (LOAD)
                // =========================
                MEM_AR: begin
                    m_araddr  <= req_addr;
                    m_arvalid <= 1'b1;

                    if (m_arready)
                        state <= MEM_R;
                end

                // =========================
                // Data Read Data (LOAD)
                // =========================
                MEM_R: begin
                    m_rready <= 1'b1;

                    if (m_rvalid) begin
                        mem_rdata <= m_rdata;
                        mem_ready <= 1'b1;

                        instr_active <= 1'b0;
                        state        <= IDLE;
                    end
                end

                // =========================
                // Data Write (STORE)
                // =========================
                MEM_AW_W: begin
                    m_awaddr  <= req_addr;
                    m_awvalid <= 1'b1;

                    m_wdata   <= req_wdata;
                    m_wvalid  <= 1'b1;

                    if (m_awready && m_wready)
                        state <= MEM_B;
                end

                MEM_B: begin
                    m_bready <= 1'b1;

                    if (m_bvalid) begin
                        mem_ready <= 1'b1;

                        instr_active <= 1'b0;
                        state        <= IDLE;
                    end
                end

                // =========================
                // MEM wait (observe mem_req again one cycle)
                // =========================
                MEM_WAIT: begin
                    if (mem_req) begin
                        req_addr     <= mem_addr;
                        req_wdata    <= mem_wdata;
                        req_is_write <= mem_write;

                        if (mem_write)
                            state <= MEM_AW_W;
                        else
                            state <= MEM_AR;
                    end
                    else begin
                        // ALU / LUI / ADDI commit here
                        instr_active <= 1'b0;
                        state        <= IDLE;
                    end
                end

            endcase
        end
    end

endmodule
