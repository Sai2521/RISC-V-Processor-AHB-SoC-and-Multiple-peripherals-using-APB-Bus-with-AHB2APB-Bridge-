module Decoder(
    input [31:0]    HADDR,
    output          HSEL_G,
    output          HSEL_T,
    output          HSEL_R
);

// Address decode logic for slave selection
assign HSEL_G = (HADDR[31:28] == 4'b0000);  //(32'h0000_0000 -> 32'h0FFF_FFFF)
assign HSEL_T = (HADDR[31:28] == 4'b0001);  //(32'h1000_0000 -> 32'h1FFF_FFFF)
assign HSEL_R = (HADDR[31:28] == 4'b0010);  //(32'h2000_0000 -> 32'h2FFF_FFFF)

endmodule