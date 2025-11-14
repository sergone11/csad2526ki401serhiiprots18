// spi_master.v - SPI Master (CPOL=0, CPHA=0, 8-бітний)
// Варіант 18: Verilog, режим Master

module spi_master (
    input  wire       clk,        // Системний такт (50 МГц)
    input  wire       rst_n,      // Активний низький скид
    input  wire       start,      // Початок передачі
    input  wire [7:0] data_in,    // Дані для передачі
    output reg  [7:0] data_out,   // Отримані дані
    output reg        data_ready, // Флаг готовності даних
    output reg        sclk,       // Такт SPI
    output reg        mosi,       // Master Out Slave In
    input  wire       miso,       // Master In Slave Out
    output reg        ss_n        // Вибір slave (активний низький)
);

    // Стани FSM
    localparam IDLE  = 2'd0;  // Очікування
    localparam LOAD  = 2'd1;  // Завантаження даних
    localparam SHIFT = 2'd2;  // Зсув даних
    localparam DONE  = 2'd3;  // Завершення

    reg [1:0] state, next_state;
    reg [7:0] shift_reg_tx, shift_reg_rx; // Регістри зсуву
    reg [3:0] bit_cnt;                    // Лічильник бітів
    reg       sclk_en;                    // Дозвіл такту SPI

    // Генерація SCLK: clk / 4 = 12.5 МГц
    reg [1:0] sclk_div;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            sclk_div <= 0;
        else if (sclk_en)
            sclk_div <= sclk_div + 1;
    end
    assign sclk = sclk_en ? sclk_div[1] : 1'b0;

    // Регістр стану FSM
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    // Логіка наступного стану
    always @(*) begin
        next_state = state;
        case (state)
            IDLE:  if (start) next_state = LOAD;
            LOAD:  next_state = SHIFT;
            SHIFT: if (bit_cnt == 7) next_state = DONE;
            DONE:  next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    // Вихідна логіка та шлях даних
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ss_n <= 1'b1;
            mosi <= 1'b0;
            shift_reg_tx <= 8'd0;
            shift_reg_rx <= 8'd0;
            bit_cnt <= 4'd0;
            data_ready <= 1'b0;
            sclk_en <= 1'b0;
            data_out <= 8'd0;
        end else begin
            data_ready <= 1'b0;
            case (state)
                IDLE: begin
                    ss_n <= 1'b1;
                    sclk_en <= 1'b0;
                    bit_cnt <= 4'd0;
                end
                LOAD: begin
                    ss_n <= 1'b0;
                    shift_reg_tx <= data_in;
                    sclk_en <= 1'b1;
                end
                SHIFT: begin
                    if (sclk_div == 2'b01) begin  // Фронт такту
                        mosi <= shift_reg_tx[7];
                        shift_reg_tx <= {shift_reg_tx[6:0], 1'b0};
                        shift_reg_rx <= {shift_reg_rx[6:0], miso};
                        if (bit_cnt < 7)
                            bit_cnt <= bit_cnt + 1;
                    end
                end
                DONE: begin
                    data_out <= shift_reg_rx;
                    data_ready <= 1'b1;
                    ss_n <= 1'b1;
                    sclk_en <= 1'b0;
                end
            endcase
        end
    end

endmodule