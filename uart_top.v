// Top-level wiring of a uartx transmitter into a uartrx receiver over a
// shared serial line. Both sides must share clk/rst and clk_frequency/baud_rate
// so their internal uclk baud generators stay in phase (see comments in
// receiver.v).
module uart_top
#(
    parameter clk_frequency = 1000000,
    parameter baud_rate     = 9600
)
(
    input            clk,
    input            rst,
    input            newd,      // assert for >= 1 baud period to start sending tx_data
    input      [7:0] tx_data,   // parallel byte to transmit
    output           donetx,    // pulses high for one baud period when uartx finishes sending
    output           donerx,    // pulses high for one baud period when uartrx finishes receiving
    output     [7:0] rx_data    // parallel byte reassembled by uartrx
);

wire tx_line;   // serial connection from uartx's tx output to uartrx's rx input

uartx #(
    .clk_frequency (clk_frequency),
    .baud_rate     (baud_rate)
) tx0 (
    .clk    (clk),
    .rst    (rst),
    .newd   (newd),
    .tx_data(tx_data),
    .tx     (tx_line),
    .donetx (donetx)
);

uartrx #(
    .clk_frequency (clk_frequency),
    .baud_rate     (baud_rate)
) rx0 (
    .clk    (clk),
    .rst    (rst),
    .rx     (tx_line),
    .donerx (donerx),
    .rx_data(rx_data)
);

endmodule
