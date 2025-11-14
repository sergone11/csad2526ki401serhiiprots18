`timescale 1ns / 1ps
// tb_spi_master.v - Testbench for SPI Master

module tb_spi_master;

    reg clk, rst_n, start;
    reg [7:0] data_in;

    wire [7:0] data_out;
    wire       data_ready;
    wire       sclk, mosi, ss_n;
    wire       miso;

    // === DUT ===
    spi_master dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .data_in(data_in),
        .data_out(data_out),
        .data_ready(data_ready),
        .sclk(sclk),
        .mosi(mosi),
        .miso(miso),
        .ss_n(ss_n)
    );

    // === SLAVE EMULATION (correct inverted echo) ===
    reg [7:0] slave_shift_reg;
    reg       miso_reg;

    always @(posedge sclk or posedge ss_n) begin
        if (ss_n) begin
            slave_shift_reg <= ~data_in;   // invert incoming byte
            miso_reg        <= 0;
        end else begin
            miso_reg <= slave_shift_reg[7];
            slave_shift_reg <= {slave_shift_reg[6:0], 1'b0};
        end
    end

    assign miso = miso_reg;

    // === VCD DUMP ===
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_spi_master);
    end

    // === CLOCK: 50 MHz (20 ns period) ===
    always #10 clk = ~clk;

    // === TEST SEQUENCE ===
    initial begin
        clk = 0; rst_n = 0; start = 0; data_in = 0;

        #40 rst_n = 1;  // Reset release

        // TEST 1
        #40 data_in = 8'hA5; start = 1;
        #20 start = 0;
        @(posedge data_ready);
        $display("TEST 1: Sent 0x%h -> Received 0x%h", 8'hA5, data_out);

        // TEST 2
        #200 data_in = 8'h55; start = 1;
        #20 start = 0;
        @(posedge data_ready);
        $display("TEST 2: Sent 0x%h -> Received 0x%h", 8'h55, data_out);

        #200 $finish;
    end

endmodule
