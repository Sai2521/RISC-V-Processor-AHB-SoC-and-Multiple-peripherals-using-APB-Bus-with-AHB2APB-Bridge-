module apb_gpio (
    input  wire        PCLK,
    input  wire        PRESETn,

    input  wire        PSEL,
    input  wire        PENABLE,
    input  wire        PWRITE,
    input  wire [31:0] PADDR,
    input  wire [31:0] PWDATA,

    output reg  [31:0] PRDATA,
    output wire        PREADY,
    output wire        PSLVERR,

    input  wire [7:0]  gpio_in,
    output wire [7:0]  gpio_out,
    output wire [7:0]  gpio_dir
);

    // GPIO registers
    reg [7:0] reg_data;
    reg [7:0] reg_dir;

    wire [7:0] pin_value;
    assign pin_value = reg_dir ? reg_data : gpio_in;

    // Write logic
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            reg_data <= 8'h00;
            reg_dir  <= 8'h00;
        end
        else if (PSEL && PENABLE && PWRITE) begin
            case (PADDR[5:2])
                2'd0: reg_data <= PWDATA[7:0]; // DATA
                2'd1: reg_dir  <= PWDATA[7:0]; // DIR
                default: ;
            endcase
        end
    end

    // Read logic
    always @(*) begin
        PRDATA = 32'h0;
        if (PSEL && PENABLE && !PWRITE) begin
            case (PADDR[5:2])
                2'd0: PRDATA = {24'h0, reg_data};
                2'd1: PRDATA = {24'h0, reg_dir};
                2'd2: PRDATA = {24'h0, pin_value};
                default: PRDATA = 32'h0;
            endcase
        end
    end


    assign PREADY = (PENABLE && PSEL) ? 1'b1 : 1'b0;
    assign PSLVERR = 1'b0;
    assign gpio_out = reg_data;
    assign gpio_dir = reg_dir;

endmodule
