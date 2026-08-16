module uartx
#(
    parameter clk_frequency = 1000000,   // system clock frequency, in Hz
    parameter baud_rate     = 9600       // desired UART baud rate, in bps
)
(
    input        clk,       // system clock
    input        rst,       // synchronous, active-high reset
    input        newd,      // assert for >= 1 baud period to start sending tx_data
    input  [7:0] tx_data,   // parallel byte to transmit
    output reg   tx,        // serial output line (idles high)
    output reg   donetx     // pulses high for one baud period when a byte finishes sending
);

// clk cycles per bit period, e.g. 1_000_000 / 9600 ~= 104
localparam clks_per_bit = clk_frequency / baud_rate;

integer baud_counter = 0;   // divides clk down to derive the baud-rate tick (uclk)
integer bit_index    = 0;   // index (0-7) of the data bit currently being shifted out

// NOTE: -g2012 (or equivalent SystemVerilog mode) is required to compile this
// enum with Icarus Verilog; plain Verilog-2001 would need `reg [1:0] state`
// with separate localparam encodings instead.
enum bit[1:0] {idle = 2'b00, start = 2'b01, transfer = 2'b10, done = 2'b11} state;

reg uclk = 0;   // baud-rate clock: toggles every clks_per_bit/2 clk cycles,
                // so its period equals one full baud period

// Baud-rate clock generator: derives uclk (frequency = baud_rate) from clk.
always@(posedge clk) begin
    if (baud_counter < clks_per_bit/2)
        baud_counter <= baud_counter + 1;
    else begin
        baud_counter <= 0;
        uclk <= ~uclk;
    end
end

reg [7:0] din;   // latched copy of tx_data, shifted onto tx one bit per baud period

// Transmit FSM: clocked by uclk (not clk) so every state/bit is held for a full
// baud period. NOTE: since this only samples newd once per baud period (up to
// clks_per_bit clk cycles), newd must stay asserted at least that long or it
// can be missed depending on uclk's phase.
always@(posedge uclk) begin
    if (rst)
        state <= idle;
    else begin
        case (state)
            idle: begin
                bit_index <= 0;
                tx        <= 1'b1;   // line idles high
                donetx    <= 1'b0;
                if (newd) begin
                    state <= transfer;
                    din   <= tx_data;  // latch the byte to send
                    tx    <= 1'b0;     // drive start bit
                end
            end

            transfer: begin
                if (bit_index <= 7) begin
                    bit_index <= bit_index + 1;
                    tx        <= din[bit_index];  // send data bits LSB first
                    state     <= transfer;
                end
                else begin
                    bit_index <= 0;
                    tx        <= 1'b1;   // drive stop bit, return line to idle level
                    state     <= idle;
                    donetx    <= 1'b1;   // held high for one baud period
                end
            end

            default: state <= idle;
        endcase
    end
end

endmodule
