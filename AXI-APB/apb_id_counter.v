module apb_id_counter (
    input  wire        PCLK,
    input  wire        PRESETn,

    input  wire        PSEL,
    input  wire        PENABLE,
    input  wire        PWRITE,
    input  wire [31:0] PADDR,
    input  wire [31:0] PWDATA,

    output reg  [31:0] PRDATA,
    output wire        PREADY,
    output wire        PSLVERR
);

    localparam [31:0] PERIPH_ID = 32'hABCD_1234;

    reg        ctrl_en;
    reg [31:0] counter;

    // Write logic
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn)
            ctrl_en <= 1'b0;
        else if (PSEL && PENABLE && PWRITE) begin
            if (PADDR[5:2] == 2'd1)
                ctrl_en <= PWDATA[0];
        end
    end

    // Counter
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn)
            counter <= 32'h0;
        else if (ctrl_en)
            counter <= counter + 1'b1;
    end

    // Read logic
    always @(*) begin
        PRDATA = 32'h0;
        if (PSEL && PENABLE && !PWRITE) begin
            case (PADDR[5:2])
                2'd0: PRDATA = PERIPH_ID;
                2'd1: PRDATA = {31'h0, ctrl_en};
                2'd2: PRDATA = counter;
                default: PRDATA = 32'h0;
            endcase
        end
    end

    assign PREADY  = 1'b1;
    assign PSLVERR = 1'b0;

endmodule
