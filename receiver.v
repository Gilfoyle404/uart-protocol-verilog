module uartrx
#(
    parameter clk_frequency = 1000000,   // system clock frequency, in Hz
    parameter baud_rate     = 9600       // desired UART baud rate, in bps
)
(
    input            clk,      // system clock
    input            rst,      // synchronous, active-high reset
    input            rx,       // serial input line (idles high), driven by a uartx's tx
    output reg       donerx,   // pulses high for one baud period when a byte finishes receiving
    output reg [7:0] rx_data   // parallel byte reassembled from the serial stream
);

// clk cycles per bit period, e.g. 1_000_000 / 9600 ~= 104
// NOTE: must match the clks_per_bit on the uartx driving rx, or bit sampling drifts.
localparam clks_per_bit = clk_frequency / baud_rate;

integer baud_counter = 0;   // divides clk down to derive the baud-rate tick (uclk)
integer bit_index    = 0;   // index (0-7) of the data bit currently being sampled

// NOTE: -g2012 (or equivalent SystemVerilog mode) is required to compile this
// enum with Icarus Verilog; plain Verilog-2001 would need `reg [1:0] state`
// with separate localparam encodings instead.
enum bit[1:0] {idle = 2'b00, transfer = 2'b01} state;

reg uclk = 0;   // baud-rate clock: toggles every clks_per_bit/2 clk cycles,
                // so its period equals one full baud period

// Baud-rate clock generator: derives uclk (frequency = baud_rate) from clk.
// Identical to the generator in uartx, so as long as both modules share clk/rst
// and the same clk_frequency/baud_rate, their uclk edges stay in phase and the
// bit sampled here on each edge is the one uartx drove on the previous edge.
always@(posedge clk) begin
    if (baud_counter < clks_per_bit/2)
        baud_counter <= baud_counter + 1;
    else begin
        baud_counter <= 0;
        uclk <= ~uclk;
    end
end

// Receive FSM: clocked by uclk (not clk) so every bit is sampled once per baud
// period, in line with tx being driven once per baud period by uartx.
always@(posedge uclk) begin
    if (rst)
        state <= idle;
    else begin
        case (state)
            idle: begin
                bit_index <= 0;
                rx_data   <= 8'h00;
                donerx    <= 1'b0;
                if (rx == 1'b0)
                    state <= transfer;   // start bit seen, begin sampling data bits
            end

            transfer: begin
                if (bit_index <= 7) begin
                    bit_index <= bit_index + 1;
                    rx_data   <= {rx, rx_data[7:1]};  // shift in data bits LSB first
                    state     <= transfer;
                end
                else begin
                    bit_index <= 0;
                    donerx    <= 1'b1;   // held high for one baud period
                    state     <= idle;   // remaining cycle covers the stop bit
                end
            end

            default: state <= idle;
        endcase
    end
end

endmodule
