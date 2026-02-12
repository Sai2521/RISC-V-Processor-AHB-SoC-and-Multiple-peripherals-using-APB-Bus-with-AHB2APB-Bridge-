`timescale 1ns/1ps

module Mux (
    input  logic         clk,
    input  logic         rst_n,

    // Selects
    input  logic         HSEL_G,
    input  logic         HSEL_T,
    input  logic         HSEL_R,

    // Data inputs
    input  logic [31:0]  HRDATA_G,
    input  logic [31:0]  HRDATA_T,
    input  logic [31:0]  HRDATA_R,

    // Handshake inputs
    input  logic         HREADY_G,
    input  logic         HREADY_T,
    input  logic         HREADY_R,

    // Response inputs
    input  logic         HRESP_G,
    input  logic         HRESP_T,
    input  logic         HRESP_R,

    // Outputs
    output logic [31:0]  HRDATA,
    output logic         HREADY,
    output logic         HRESP
);

    // -----------------------------
    // Registered signals
    // -----------------------------
    logic HSEL_G_r, HSEL_T_r, HSEL_R_r;

    // -----------------------------
    // Sequential logic
    // -----------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            HSEL_G_r     <= 1'b0;
            HSEL_T_r     <= 1'b0;
            HSEL_R_r     <= 1'b0;
        end else begin
            HSEL_G_r     <= HSEL_G;
            HSEL_T_r     <= HSEL_T;
            HSEL_R_r     <= HSEL_R;
        end
    end

    // -----------------------------
    // Output mux
    // -----------------------------
    always_comb begin
        // Default values
        HRDATA = 32'h0;
        HREADY = 1'b1;
        HRESP  = 1'b0;

        if (HSEL_G_r) begin
            HRDATA = HRDATA_G;
            HREADY = HREADY_G;
            HRESP  = HRESP_G;
        end else if (HSEL_T_r) begin
            HRDATA = HRDATA_T;
            HREADY = HREADY_T;
            HRESP  = HRESP_T;
        end else if (HSEL_R_r) begin
            HRDATA = HRDATA_R;
            HREADY = HREADY_R;
            HRESP  = HRESP_R;
        end
    end

endmodule
