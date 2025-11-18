`timescale 1ns / 1ps

module spi_master_tb;
    localparam CLK_PERIOD = 20;

    reg clk_tb;
    reg reset_tb;
    reg i_start_tb;
    reg [7:0] i_tx_byte_tb;

    wire o_done_tb;
    wire [7:0] o_rx_byte_tb;
    wire o_mosi_tb;
    wire o_sck_tb;
    wire o_ss_tb;

    // Instantiate UUT
    spi_master uut (
        .clk(clk_tb), .reset(reset_tb), .i_start(i_start_tb),
        .i_tx_byte(i_tx_byte_tb), .o_done(o_done_tb), .o_rx_byte(o_rx_byte_tb),
        .i_miso(o_mosi_tb), // loopback
        .o_mosi(o_mosi_tb), .o_sck(o_sck_tb), .o_ss(o_ss_tb)
    );
  // ---- Waveform setup ----
    initial begin
        $dumpfile("wave.vcd");  // EPWave використовує автоматично
        $dumpvars(0, uut);      // всі сигнали UUT
    end

    // Clock generation
    initial clk_tb = 0;
    always #(CLK_PERIOD/2) clk_tb = ~clk_tb;

    initial begin
        $display("Starting SPI Master Testbench (Loopback Mode)...");
        reset_tb <= 1; i_start_tb <= 0; i_tx_byte_tb <= 8'h00;
        #(CLK_PERIOD*5);
        reset_tb <= 0;
        #(CLK_PERIOD*10);

        $display("TEST 1: Sending 0xA5...");
        i_start_tb <= 1; i_tx_byte_tb <= 8'hA5;
        #CLK_PERIOD; i_start_tb <= 0;
        wait(o_done_tb == 1);
        $display("TEST 1: Done flag received. Sent: 0xA5, Received: %h", o_rx_byte_tb);
        #(CLK_PERIOD*20);

        $display("TEST 2: Sending 0xF0...");
        i_start_tb <= 1; i_tx_byte_tb <= 8'hF0;
        #CLK_PERIOD; i_start_tb <= 0;
        wait(o_done_tb == 1);
        $display("TEST 2: Done flag received. Sent: 0xF0, Received: %h", o_rx_byte_tb);
        #(CLK_PERIOD*20);

        $display("Simulation Finished.");
        $finish;
    end 
endmodule
