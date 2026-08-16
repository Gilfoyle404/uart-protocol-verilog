`timescale 1ns/1ps

// Self-checking testbench for uart_top: drives uartx (via uart_top's newd/
// tx_data) with random bytes and checks that uartrx reconstructs the same
// byte on rx_data, over uart_top's internal tx0.tx -> rx0.rx loopback.
module uart_tb;

localparam CLK_FREQUENCY  = 1000000;
localparam BAUD_RATE      = 9600;
localparam NUM_TESTS      = 10;
localparam CLKS_PER_BIT   = CLK_FREQUENCY / BAUD_RATE;   // must mirror uartx/uartrx's clks_per_bit
localparam NEWD_HOLD_CLKS = 2 * CLKS_PER_BIT;            // > 1 baud period, so newd is always sampled

reg        clk = 0;
reg        rst = 0;
reg        newd = 0;
reg  [7:0] tx_data = 0;
wire       donetx;
wire       donerx;
wire [7:0] rx_data;

integer i;
integer errors = 0;
reg [7:0] expected_data;

uart_top #(
    .clk_frequency (CLK_FREQUENCY),
    .baud_rate     (BAUD_RATE)
) dut (
    .clk     (clk),
    .rst     (rst),
    .newd    (newd),
    .tx_data (tx_data),
    .donetx  (donetx),
    .donerx  (donerx),
    .rx_data (rx_data)
);

always #5 clk = ~clk;

initial begin
    rst  = 1;
    newd = 0;
    repeat (5) @(posedge clk);
    rst = 0;
    @(posedge clk);

    for (i = 0; i < NUM_TESTS; i = i + 1) begin
        expected_data = $urandom;
        tx_data = expected_data;

        // Hold newd asserted for more than one baud period so uartx's
        // uclk-synchronous FSM (which only samples newd while idle) is
        // guaranteed to catch it regardless of uclk's phase relative to
        // clk. Sync to clk (not the DUT's internal uclk) so there's no
        // race between this assignment and the FSM's own sampling edge.
        newd = 1;
        repeat (NEWD_HOLD_CLKS) @(posedge clk);
        newd = 0;

        @(posedge donetx);   // tx0 finished shifting this byte out
        @(posedge donerx);   // rx0 finished reassembling it

        if (rx_data !== expected_data) begin
            errors = errors + 1;
            $display("[%0t] FAIL: sent 0x%02h, received 0x%02h", $time, expected_data, rx_data);
        end
        else
            $display("[%0t] PASS: sent 0x%02h, received 0x%02h", $time, expected_data, rx_data);
    end

    if (errors == 0)
        $display("All %0d tests passed.", NUM_TESTS);
    else
        $display("%0d of %0d tests FAILED.", errors, NUM_TESTS);

    $finish;
end

initial begin
    $dumpfile("uart_tb.vcd");
    $dumpvars(0, uart_tb);
end

endmodule
