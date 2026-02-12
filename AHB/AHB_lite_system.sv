module AHB_lite_system #(
    parameter REG_WIDTH = 8,
    parameter REG_DEPTH = 32,
    parameter GPIO_WIDTH = 8,
    parameter COUNTER_WIDTH = 32
)(
    input                       HCLK,
    input                       HRESETn,
    input  [31:0]               PADDR,
    input                       PWRITE,
    input  [1:0]                PSIZE,
    input  [1:0]                PTRANS,
    input  [2:0]                PBURST,
    input  [31:0]               PWDATA,
    input  [GPIO_WIDTH-1:0]     GPIO_in_portA,      
    input  [GPIO_WIDTH-1:0]     GPIO_in_portB,      
    input  [GPIO_WIDTH-1:0]     GPIO_in_portC,      
    input  [GPIO_WIDTH-1:0]     GPIO_in_portD,      
    input                       Register_File_En,
    input                       GPIO_En,
    input                       Timer_En,

    output                      PREADY,
    output                      PRESP,
    output [31:0]               PRDATA,
    output [GPIO_WIDTH-1:0]     GPIO_out_portA,     
    output [GPIO_WIDTH-1:0]     GPIO_out_portB,     
    output [GPIO_WIDTH-1:0]     GPIO_out_portC,     
    output [GPIO_WIDTH-1:0]     GPIO_out_portD    
    
);

    // internal connections between master and slaves
    // from Master to slaves
    logic [31:0] HADDR;
    logic [31:0] HWDATA;
    logic [31:0] HRDATA;
    logic [1:0]  HSIZE;
    logic [2:0]  HBURST;
    logic [1:0]  HTRANS;
    logic        HWRITE;
    logic        HREADY;
    logic        HRESP;


    // Internal signals
    logic rst_n; 

    logic               HSEL_G, HSEL_T, HSEL_R;
    logic [31:0]        gpio_rd_data, timer_rd_data, register_file_rd_data;
    logic               gpio_ready, timer_ready, register_file_ready;
    logic               gpio_response, timer_response, register_file_response;

    logic [31:0] HRDATA_G, HRDATA_T, HRDATA_R;
    logic        HREADY_G, HREADY_T, HREADY_R;
    logic        HRESP_G, HRESP_T, HRESP_R;

    logic        gpio_we, timer_we, register_file_we;
    logic        gpio_re, timer_re, register_file_re;

    logic [31:0] Addr_G;
    logic [1:0]  size_G;
    logic [31:0] wd_data_G;

    logic [31:0] Addr_T;
    logic [1:0]  size_T;
    logic [31:0] wd_data_T;

    logic [31:0] Addr_R;
    logic [1:0]  size_R;
    logic [31:0] wd_data_R;


    // -------------------------------
    // Reset Synchronizer
    // -------------------------------
    Rst_sync Reset_synchronizer(
        .clk(HCLK),
        .async_rst_n(HRESETn),
        .sync_rst_n(rst_n)
    );

    // -------------------------------
    // AHB_master Interface
    // -------------------------------
    AHB_lite_master master(
        .HCLK(HCLK),
        .HRESETn(rst_n),
        .PADDR(PADDR),
        .PWRITE(PWRITE),
        .PSIZE(PSIZE),
        .PTRANS(PTRANS),
        .PBURST(PBURST),
        .PWDATA(PWDATA),    
        .HADDR(HADDR),
        .HWRITE(HWRITE),
        .HSIZE(HSIZE),
        .HBURST(HBURST),
        .HTRANS(HTRANS),
        .HWDATA(HWDATA),
        .HREADY(HREADY),
        .HRESP(HRESP),
        .HRDATA(HRDATA),
        .PREADY(PREADY),
        .PRESP(PRESP),
        .PRDATA(PRDATA)
    );

    // -------------------------------
    // Decoder: Maps address to slave
    // -------------------------------
    Decoder AHB_Decoder_block (
        .HADDR(HADDR),
        .HSEL_G(HSEL_G),
        .HSEL_T(HSEL_T),
        .HSEL_R(HSEL_R)
    );

    // ------------------------------------------------
    // AHB Slave Interface: Register File
    // ------------------------------------------------
    AHB_slave_if AHB_Register_file_Interface_block (
        .HCLK(HCLK),
        .HRESETn(rst_n),
        .HADDR(HADDR),
        .HWRITE(HWRITE),
        .HSIZE(HSIZE),
        .HTRANS(HTRANS),
        .HWDATA(HWDATA),

        .HSEL_P(HSEL_R),
        .HREADY(HREADY),

        .peripheral_rd_data(register_file_rd_data),
        .peripheral_ready(register_file_ready),
        .peripheral_response(register_file_response),

        .HRDATA_P(HRDATA_R),

        .HREADY_P(HREADY_R),

        .HRESP_P(HRESP_R),

        .peripheral_we(register_file_we),

        .peripheral_re(register_file_re),

        .Addr(Addr_R),
        .size(size_R),
        .wd_data(wd_data_R)      
    );

    // -------------------------------------------
    // Register File Slave (Address-mapped)
    // -------------------------------------------
    Register_File #(
        .REG_WIDTH(REG_WIDTH), 
        .REG_DEPTH(REG_DEPTH)
    ) Register_File_slave (
        .clk(HCLK),
        .rst_n(rst_n),
        .en(Register_File_En),                        
        .Addr(Addr_R[$clog2(REG_DEPTH)-1:0]),  // Extract lower index bits
        .size(size_R),
        .we(register_file_we),
        .re(register_file_re),
        .wd_data(wd_data_R),
        .rd_data(register_file_rd_data),
        .done(register_file_ready),         // Slave ready signal
        .check(register_file_response)      // Slave error response
    );

    // ------------------------------------------------
    // AHB Slave Interface: GPIO
    // ------------------------------------------------
    AHB_slave_if AHB_GPIO_Interface_block (
        .HCLK(HCLK),
        .HRESETn(rst_n),
        .HADDR(HADDR),
        .HWRITE(HWRITE),
        .HSIZE(HSIZE),
        .HTRANS(HTRANS),
        .HWDATA(HWDATA),

        .HSEL_P(HSEL_G),

        .peripheral_rd_data(gpio_rd_data),
        .peripheral_ready(gpio_ready),
        .peripheral_response(gpio_response),

        .HRDATA_P(HRDATA_G),

        .HREADY_P(HREADY_G),

        .HRESP_P(HRESP_G),

        .peripheral_we(gpio_we),

        .peripheral_re(gpio_re),

        .Addr(Addr_G),
        .size(size_G),
        .wd_data(wd_data_G)      
    );

    // -------------------------------------------
    // GPIO Slave (Address-mapped)
    // -------------------------------------------
    GPIO #(
        .GPIO_WIDTH(GPIO_WIDTH)
    ) GPIO_slave (
        .clk(HCLK),
        .rst_n(rst_n),
        .en(GPIO_En),                        
        .Addr(Addr_G[2:0]),  
        .size(size_G),
        .we(gpio_we),
        .re(gpio_re),
        .wd_data(wd_data_G),
        .GPIO_in_portA(GPIO_in_portA),      
        .GPIO_in_portB(GPIO_in_portB),     
        .GPIO_in_portC(GPIO_in_portC),      
        .GPIO_in_portD(GPIO_in_portD),      
        .rd_data(gpio_rd_data),
        .GPIO_out_portA(GPIO_out_portA),     
        .GPIO_out_portB(GPIO_out_portB),     
        .GPIO_out_portC(GPIO_out_portC),     
        .GPIO_out_portD(GPIO_out_portD),     
        .done(gpio_ready),         // Slave ready signal
        .check(gpio_response)      // Slave error response
    );

    // ------------------------------------------------
    // AHB Slave Interface: Timer
    // ------------------------------------------------
    AHB_slave_if AHB_Timer_Interface_block (
        .HCLK(HCLK),
        .HRESETn(rst_n),
        .HADDR(HADDR),
        .HWRITE(HWRITE),
        .HSIZE(HSIZE),
        .HTRANS(HTRANS),
        .HWDATA(HWDATA),

        .HSEL_P(HSEL_T),

        .peripheral_rd_data(timer_rd_data),
        .peripheral_ready(timer_ready),
        .peripheral_response(timer_response),

        .HRDATA_P(HRDATA_T),

        .HREADY_P(HREADY_T),

        .HRESP_P(HRESP_T),

        .peripheral_we(timer_we),

        .peripheral_re(timer_re),

        .Addr(Addr_T),
        .size(size_T),
        .wd_data(wd_data_T)      
    );

    // -------------------------------------------
    // Timer Slave (Address-mapped)
    // -------------------------------------------
    Timer #(
        .COUNTER_WIDTH(COUNTER_WIDTH)
    ) Timer_slave (
        .clk(HCLK),
        .rst_n(rst_n),
        .en(Timer_En),                        
        .Addr(Addr_T[1:0]),  
        .size(size_T),
        .we(timer_we),
        .re(timer_re),
        .load(wd_data_T[COUNTER_WIDTH-1:0]),
        .counter_value(timer_rd_data[COUNTER_WIDTH-1:0]),
        .done(timer_ready),         // Slave ready signal
        .check(timer_response)      // Slave error response
    );



    // ---------------------------------------
    // Multiplexer: Choose which slave returns
    // ---------------------------------------
    Mux AHB_Multiplexer_block (
        .clk(HCLK),
        .rst_n(rst_n),
        
        .HSEL_G(HSEL_G),
        .HSEL_T(HSEL_T),
        .HSEL_R(HSEL_R),

        .HRDATA_G(HRDATA_G),
        .HRDATA_T(HRDATA_T),
        .HRDATA_R(HRDATA_R),

        .HREADY_G(HREADY_G),
        .HREADY_T(HREADY_T),
        .HREADY_R(HREADY_R),

        .HRESP_G(HRESP_G),
        .HRESP_T(HRESP_T),   
        .HRESP_R(HRESP_R),

        .HRDATA(HRDATA),
        .HREADY(HREADY),
        .HRESP(HRESP)    
    );

endmodule
