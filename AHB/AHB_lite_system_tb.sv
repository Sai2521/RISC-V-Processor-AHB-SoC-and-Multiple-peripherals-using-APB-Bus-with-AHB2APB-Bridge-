`timescale 1ns/1ps

module AHB_lite_system_tb;

    // Parameters
    parameter CLK_PERIOD    = 10;
    parameter REG_WIDTH     = 8;
    parameter REG_DEPTH     = 32;
    parameter GPIO_WIDTH    = 8;
    parameter COUNTER_WIDTH = 32;

    // Signals declaration
    logic                       HCLK;
    logic                       HRESETn;
    logic  [31:0]               PADDR;
    logic                       PWRITE;
    logic  [31:0]               PWDATA;
    logic  [GPIO_WIDTH-1:0]     GPIO_in_portA;      
    logic  [GPIO_WIDTH-1:0]     GPIO_in_portB;      
    logic  [GPIO_WIDTH-1:0]     GPIO_in_portC;      
    logic  [GPIO_WIDTH-1:0]     GPIO_in_portD;      
    logic                       Register_File_En;
    logic                       GPIO_En;
    logic                       Timer_En;

    logic                       PREADY;
    logic                       PRESP;
    logic  [31:0]               PRDATA;
    logic [GPIO_WIDTH-1:0]      GPIO_out_portA;     
    logic [GPIO_WIDTH-1:0]      GPIO_out_portB;     
    logic [GPIO_WIDTH-1:0]      GPIO_out_portC;     
    logic [GPIO_WIDTH-1:0]      GPIO_out_portD;

    // Testing signals
    logic [31:0] tst_data [15:0];
    int correct_count = 0;
    int error_count   = 0; 

    // Typedef enums
    typedef enum logic [1:0] {IDLE, BUSY, NONSEQ, SEQ} Transfer_state;
    typedef enum logic [2:0] {SINGLE, INCR, WRAP4, INCR4, WRAP8, INCR8, WRAP16, INCR16} Burst_state;
    typedef enum logic [1:0] {BYTE, HALFWORD, WORD} Size_state;

    Transfer_state PTRANS;
    Burst_state    PBURST;
    Size_state     PSIZE;

    logic [31:0] data_q4 [$] = {32'hA, 32'hB, 32'hC, 32'hD};
    logic [31:0] data_q8 [$] = {32'h10,32'h11,32'h12,32'h13,32'h14,32'h15,32'h16,32'h17};
    logic [31:0] data_q16[$] = {32'h20,32'h21,32'h22,32'h23,32'h24,32'h25,32'h26,32'h27,
                             32'h28,32'h29,32'h2A,32'h2B,32'h2C,32'h2D,32'h2E,32'h2F};


    // DUT instantiation
    AHB_lite_system #(
        .REG_WIDTH(REG_WIDTH),
        .REG_DEPTH(REG_DEPTH),
        .GPIO_WIDTH(GPIO_WIDTH),
        .COUNTER_WIDTH(COUNTER_WIDTH)
    ) DUT (
        .HCLK(HCLK),
        .HRESETn(HRESETn),
        .PADDR(PADDR),
        .PWRITE(PWRITE),
        .PSIZE(PSIZE),
        .PTRANS(PTRANS),
        .PBURST(PBURST),
        .PWDATA(PWDATA),
        .GPIO_in_portA(GPIO_in_portA),
        .GPIO_in_portB(GPIO_in_portB),
        .GPIO_in_portC(GPIO_in_portC),
        .GPIO_in_portD(GPIO_in_portD),
        .Register_File_En(Register_File_En),
        .GPIO_En(GPIO_En),
        .Timer_En(Timer_En),
        .PREADY(PREADY),
        .PRESP(PRESP),
        .PRDATA(PRDATA),
        .GPIO_out_portA(GPIO_out_portA),
        .GPIO_out_portB(GPIO_out_portB),
        .GPIO_out_portC(GPIO_out_portC),
        .GPIO_out_portD(GPIO_out_portD)
    );

    // Clock generation
    initial begin
        HCLK = 0;
        forever #(CLK_PERIOD/2) HCLK = ~HCLK;
    end

    initial begin
        $dumpfile("AHB_lite_system.vcd");
        $dumpvars(0, AHB_lite_system_tb);

        // Initialize inputs
        HRESETn = 0;
        PADDR   = 0;
        PWDATA  = 0;
        PWRITE  = 0;
        PSIZE   = WORD;
        PTRANS  = IDLE;
        PBURST  = SINGLE;
        Register_File_En = 0;
        GPIO_En = 0;
        Timer_En = 0;
        GPIO_in_portA = 0;
        GPIO_in_portB = 0;
        GPIO_in_portC = 0;
        GPIO_in_portD = 0;
        #(2*CLK_PERIOD);

        HRESETn = 1;
        #(2*CLK_PERIOD);

    // ------------------------------------------------
    // Register File Test cases
    // ------------------------------------------------
        Register_File_En = 1;

        // Simple Write in Address 1
        Single_Write(32'h2000_0000, 1'b1, WORD, NONSEQ, SINGLE, 32'h0000_000A);
        // Wait for transfer completion
        wait(PREADY);
        check_write(32'h0000_000A, 1'b1, 1'b0);

        Single_Write(32'h2000_0004, 1'b1, WORD, NONSEQ, SINGLE, 32'h0000_000B);
        wait(PREADY);
        check_write(32'h0000_000B, 1'b1, 1'b0);

        // Simple Read from Address 1
        Single_Read(32'h2000_0000, 1'b0, WORD, NONSEQ, SINGLE);
        wait(PREADY);
        check_read(32'h0000_000A, 1'b1, 1'b0);

        Single_Read(32'h2000_0004, 1'b0, WORD, NONSEQ, SINGLE);
        wait(PREADY);
        check_read(32'h0000_000B, 1'b1, 1'b0);

        // HRESP test - invalid byte write
        Single_Write(32'h2000_0004, 1'b1, BYTE, NONSEQ, SINGLE, 32'h0000_FFFA);
        wait(PREADY);
        check_write(32'h0000_FFFA, 1'b1, 1'b1);
        PTRANS = IDLE;
        @(posedge HCLK);

        // Incremental Write with INCR4
        burst_write(32'h2000_0000, WORD, INCR4, 4, data_q4);

        // Incremental Read with INCR4
        burst_read(32'h2000_0000, WORD, INCR4, 4);

        // Incremental Write with INCR8
        burst_write(32'h2000_0000, HALFWORD, INCR8, 8, data_q8);

        // Incremental Read with INCR8
        burst_read(32'h2000_0000, HALFWORD, INCR8, 8);

        // Incremental Write with INCR16
        burst_write(32'h2000_0000, HALFWORD, INCR16, 16, data_q16);

        // Incremental Read with INCR16
        burst_read(32'h2000_0000, HALFWORD, INCR16, 16);

        // Simple Write in Address 1
        Single_Write(32'h2000_0000, 1'b1, WORD, NONSEQ, SINGLE, 32'h0000_000A);
        // Wait for transfer completion
        wait(PREADY);
        check_write(32'h0000_000A, 1'b1, 1'b0);

        // Simple Read from Address 1
        Single_Read(32'h2000_0000, 1'b0, WORD, NONSEQ, SINGLE);
        wait(PREADY);
        check_read(32'h0000_000A, 1'b1, 1'b0);
        PTRANS = IDLE;
        @(posedge HCLK);

        // Wrapping write with WRAP4
        burst_write(32'h2000_0008, BYTE, WRAP4, 4, data_q4);

        // Wrapping read with WRAP4
        burst_read(32'h2000_0008, BYTE, WRAP4, 4);

        // Wrapping write with WRAP8
        burst_write(32'h2000_0008, BYTE, WRAP8, 8, data_q8);

        // Wrapping read with WRAP8
        burst_read(32'h2000_0008, BYTE, WRAP8, 8);

        // Wrapping write with WRAP16
        burst_write(32'h2000_0008, BYTE, WRAP16, 16, data_q16);

        // Wrapping read with WRAP16
        burst_read(32'h2000_0008, BYTE, WRAP16, 16);


        Register_File_En = 0;
        #(2*CLK_PERIOD);

    // // ------------------------------------------------
    // // GPIO Test cases
    // // ------------------------------------------------
    //     GPIO_En = 1;
    //     GPIO_in_portA = 8'b0;
    //     GPIO_in_portB = 8'b0;
    //     GPIO_in_portC = 8'b0;
    //     GPIO_in_portD = 8'b0;

    //     // Incremental Drive output pins with INCR4
    //     tst_data = '{32'hA, 32'hB, 32'hC, 32'hD};
    //     burst_write(32'h0000_0004, BYTE, INCR4, 4, tst_data[3:0]);
    //     #CLK_PERIOD;

    //     // Incremental Read input pins with INCR4
    //     GPIO_in_portA = 8'b1000_0011;
    //     GPIO_in_portB = 8'b0111_0110;
    //     GPIO_in_portC = 8'b0010_0001;
    //     GPIO_in_portD = 8'b0011_0011;
    //     burst_read(32'h0000_0000, BYTE, INCR4, 4);
    //     #CLK_PERIOD;

    //     // Wrong write (read-only address)
    //     Single_Write(32'h0000_0000, 1'b1, BYTE, NONSEQ, SINGLE, 32'h0000_000A);
    //     wait(PREADY);
    //     check_write(32'h0000_000A, 1'b1, 1'b1);
    //     #CLK_PERIOD;

    //     // Wrong read (invalid addr)
    //     Single_Read(32'h0000_0004, 1'b0, BYTE, NONSEQ, SINGLE);
    //     wait(PREADY);
    //     // Expect error response
    //     if (PRESP === 1'b1) correct_count++;
    //     else error_count++;
    //     #CLK_PERIOD;

    //     // Invalid width
    //     Single_Write(32'h0000_0004, 1'b1, BYTE, NONSEQ, SINGLE, 32'h0000_ABCD);
    //     wait(PREADY);
    //     check_write(32'h0000_ABCD, 1'b1, 1'b1);
    //     #CLK_PERIOD;

    // // ------------------------------------------------
    // // Timer Test cases
    // // ------------------------------------------------
    //     Timer_En = 1;

    //     // Load value
    //     Single_Write(32'h1000_0000, 1'b1, WORD, NONSEQ, SINGLE, 32'h0000_000A);
    //     wait(PREADY);
    //     check_write(32'h0000_000A, 1'b1, 1'b0);
    //     #CLK_PERIOD;

    //     // Mode config
    //     Single_Write(32'h1000_0004, 1'b1, WORD, NONSEQ, SINGLE, 32'h0000_0002);
    //     wait(PREADY);
    //     check_write(32'h0000_0002, 1'b1, 1'b0);
    //     #CLK_PERIOD;

    //     PTRANS = IDLE;
    //     #(11*CLK_PERIOD);

    //     Single_Read(32'h1000_0000, 1'b0, WORD, NONSEQ, SINGLE);
    //     wait(PREADY);
    //     // Check read value - should be less than initial due to counting
    //     if (PRDATA < 32'hA && PREADY && !PRESP) correct_count++;
    //     else error_count++;
    //     #CLK_PERIOD;

        PTRANS = IDLE;
        #(2*CLK_PERIOD);

        $display("----------------------------------------------");
        $display("Correct transactions : %0d", correct_count);
        $display("Error   transactions : %0d", error_count);
        $finish;
    end

    // ------------------------------
    // Tasks
    // ------------------------------
    task IDLE_state();
        begin
            PTRANS = IDLE;
            #(CLK_PERIOD);
        end
    endtask

    task Single_Write(
        input logic [31:0]      Address,
        input logic             Write,
        input Size_state        Size,
        input Transfer_state    transfer_type,
        input Burst_state       BURST_type,
        input logic [31:0]      DATA
    );
    begin
        @(posedge HCLK);
        PADDR  = Address;
        PWRITE = Write;
        PSIZE  = Size;
        PTRANS = transfer_type;
        PBURST = BURST_type;
        PWDATA = DATA;
    end
    endtask

    task Single_Read(
        input logic [31:0]      Address,
        input logic             Readn,
        input Size_state        Size,
        input Transfer_state    transfer_type,
        input Burst_state       BURST_type
    );
    begin
        @(posedge HCLK);
        PADDR  = Address;
        PWRITE = Readn;
        PSIZE  = Size;
        PTRANS = transfer_type;
        PBURST = BURST_type;
    end
    endtask

    // Burst Write
    task automatic burst_write(input [31:0] start_addr, input Size_state size,
                             input Burst_state burst, input int beats, input [31:0] data []);
        int i;
        logic [31:0] addr;
        begin
            addr = start_addr;
            for (i = 0; i < beats; i++) begin
                @(posedge HCLK);
                PADDR  = addr;
                PWDATA = data[i];
                PWRITE = 1'b1;
                PSIZE  = size;
                PBURST = burst;
                PTRANS = (i == 0) ? NONSEQ : SEQ;
                // Wait for transfer completion
                wait(PREADY);
            end
            @(posedge HCLK);
        end
    endtask

    // Burst Read
    task automatic burst_read(input [31:0] start_addr, input Size_state size,
                             input Burst_state burst, input int beats);
        int i;
        logic [31:0] addr;
        begin
            addr = start_addr;
            for (i = 0; i < beats; i++) begin
                @(posedge HCLK);
                PADDR  = addr;
                PWRITE = 1'b0;
                PSIZE  = size;
                PBURST = burst;
                PTRANS = (i == 0) ? NONSEQ : SEQ;
                // Wait for transfer completion
                wait(PREADY);
                // Check read data (basic check - should be enhanced with expected values)
                if (PREADY && !PRESP) begin
                    $display("Read data[%0d]: %h", i, PRDATA);
                    correct_count++;
                end else begin
                    $display("Read error at beat %0d", i);
                    error_count++;
                end
            end
            @(posedge HCLK);
        end
    endtask

    // ------------------------------
    // Check functions
    // ------------------------------
    task check_write(
        input logic [31:0] DATA_expected,
        input logic        PREADY_expected,
        input logic        PRESP_expected
    );
    begin
        if (PWDATA == DATA_expected &&
            PREADY == PREADY_expected &&
            PRESP  == PRESP_expected) begin
            $display("[%0t] Write PASS: DATA=%h", $time, PWDATA);
            correct_count++;
        end
        else begin
            $display("[%0t] Write FAIL: DATA=%h (exp=%h)", $time, PWDATA, DATA_expected);
            $display("  PREADY: %0d (expected %0d)", PREADY, PREADY_expected);
            $display("  PRESP : %0d (expected %0d)", PRESP, PRESP_expected);
            error_count++;
        end
    end
    endtask

    task check_read(
        input logic [31:0] DATA_expected,
        input logic        PREADY_expected,
        input logic        PRESP_expected
    );
    begin
        if (PRDATA == DATA_expected &&
            PREADY == PREADY_expected &&
            PRESP  == PRESP_expected) begin
            $display("[%0t] Read PASS: DATA=%h", $time, PRDATA);
            correct_count++;
        end
        else begin
            $display("[%0t] Read FAIL: DATA=%h (exp=%h)", $time, PRDATA, DATA_expected);
            $display("  PREADY: %0d (expected %0d)", PREADY, PREADY_expected);
            $display("  PRESP : %0d (expected %0d)", PRESP, PRESP_expected);
            error_count++;
        end
    end
    endtask

endmodule