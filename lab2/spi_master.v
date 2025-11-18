module spi_master (
    // ---- Global Signals ----
    input wire clk,
    input wire reset,
    // ---- Control Interface ----
    input wire i_start,
    input wire [7:0] i_tx_byte,
    output reg o_done,
    output reg [7:0] o_rx_byte,
    // ---- SPI Lines ----
    input wire i_miso,
    output reg o_mosi,
    output reg o_sck,
    output reg o_ss
);
    // ---- Parameters ----
    localparam CLK_DIV_RATIO = 25; // 50MHz / (1MHz * 2) = 25

    // ---- FSM State Parameters ----
    localparam S_IDLE  = 2'b00;
    localparam S_START = 2'b01;
    localparam S_SHIFT = 2'b10;
    localparam S_STOP  = 2'b11;

    // ---- FSM Internal Registers ----
    reg [1:0] state_reg = S_IDLE;
    reg [$clog2(CLK_DIV_RATIO):0] clk_div_counter = 0;
    reg [3:0] bit_counter = 0;

    // ---- Internal Wires for module communication ----
    reg tx_load_reg;
    reg rx_sample_trigger_reg;
    reg tx_shift_trigger_reg;
    wire w_mosi_bit;
    wire [7:0] w_rx_byte;

    // ---- Transmitter (Tx) ----
    reg [7:0] tx_shift_reg = 0;
    always @(posedge clk or posedge reset) begin
        if (reset) tx_shift_reg <= 0;
        else begin
            if (tx_load_reg) tx_shift_reg <= i_tx_byte;
            else if (tx_shift_trigger_reg) tx_shift_reg <= tx_shift_reg << 1;
        end
    end
    assign w_mosi_bit = tx_shift_reg[7];

    // ---- Receiver (Rx) ----
    reg [7:0] rx_shift_reg = 0;
    always @(posedge clk or posedge reset) begin
        if (reset) rx_shift_reg <= 0;
        else if (rx_sample_trigger_reg) rx_shift_reg <= {rx_shift_reg[6:0], i_miso};
    end
    assign w_rx_byte = rx_shift_reg;

    // ---- FSM ----
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state_reg <= S_IDLE;
            o_sck <= 0; o_ss <= 1; o_mosi <= 0; o_done <= 0;
            bit_counter <= 0; clk_div_counter <= 0;
            o_rx_byte <= 0;
            tx_load_reg <= 0; rx_sample_trigger_reg <= 0; tx_shift_trigger_reg <= 0;
        end else begin
            tx_load_reg <= 0; rx_sample_trigger_reg <= 0; tx_shift_trigger_reg <= 0;
            case (state_reg)
                S_IDLE: begin
                    o_done <= 0; o_ss <= 1; o_sck <= 0; o_mosi <= 0;
                    if (i_start) begin
                        tx_load_reg <= 1; bit_counter <= 8; state_reg <= S_START;
                    end
                end
                S_START: begin
                    o_ss <= 0; o_mosi <= w_mosi_bit;
                    state_reg <= S_SHIFT; clk_div_counter <= 0;
                end
                S_SHIFT: begin
                    if (bit_counter > 0) begin
                        if (clk_div_counter == CLK_DIV_RATIO - 1) begin
                            o_sck <= 0; tx_shift_trigger_reg <= 1;
                            clk_div_counter <= 0; bit_counter <= bit_counter - 1;
                        end else if (clk_div_counter == (CLK_DIV_RATIO/2) - 1) begin
                            o_sck <= 1; rx_sample_trigger_reg <= 1;
                            clk_div_counter <= clk_div_counter + 1;
                        end else if (clk_div_counter == 1) begin
                            o_mosi <= w_mosi_bit; clk_div_counter <= clk_div_counter + 1;
                        end else clk_div_counter <= clk_div_counter + 1;
                    end else state_reg <= S_STOP;
                end
                S_STOP: begin
                    o_ss <= 1; o_sck <= 0; o_mosi <= 0; o_done <= 1;
                    o_rx_byte <= w_rx_byte; state_reg <= S_IDLE;
                end
                default: state_reg <= S_IDLE;
            endcase
        end
    end
endmodule
