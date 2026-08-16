# UART Communication Protocol — Verilog

Implementation of a UART (Universal Asynchronous Receiver/Transmitter) in Verilog: a transmitter, a receiver, and a top-level module wiring the two together over a shared serial line.

## Overview

UART is an asynchronous serial communication protocol used for point-to-point data exchange without a shared clock. This project implements:

- **UART Transmitter (`uartx`)** — serializes a parallel byte and sends it out `tx`
- **UART Receiver (`uartrx`)** — deserializes an incoming serial stream on `rx` back into a parallel byte
- **Baud Rate Generator** — each module derives its own baud-rate tick (`uclk`) from `clk`; both must be given the same `clk_frequency`/`baud_rate` and a shared `clk`/`rst` so their tick generators stay in phase
- **`uart_top`** — instantiates `uartx` and `uartrx` and connects `tx` straight into `rx`

## Frame Format

```
 Idle | Start | D0 D1 D2 D3 D4 D5 D6 D7 | Stop | Idle
  1   |   0   |   8 data bits (LSB first)   |  1   |  1
```

- **Start bit**: 1 bit, always `0`
- **Data bits**: 8 bits, LSB first
- **Stop bit**: 1 bit, always `1`
- Line idles `HIGH` between frames
- No parity bit — not implemented

## Project Structure

```
uart-protocol-verilog/
├── transmitter.v   # uartx  — parallel-to-serial transmitter
├── receiver.v      # uartrx — serial-to-parallel receiver
├── uart_top.v      # wires a uartx's tx into a uartrx's rx
└── README.md
```

## Parameters

Both `uartx` and `uartrx` (and `uart_top`, which passes them through) take the same two parameters:

| Parameter        | Description                        | Default   |
|-------------------|-------------------------------------|-----------|
| `clk_frequency`   | System clock frequency, in Hz       | 1,000,000 |
| `baud_rate`       | Desired UART baud rate, in bps      | 9600      |

Data width (8 bits) and stop bits (1) are fixed, not parameterized.

## Getting Started

### Prerequisites

- A SystemVerilog-capable simulator (e.g., Icarus Verilog with `-g2012`, ModelSim, Vivado Simulator) — the FSMs use SystemVerilog `enum` state declarations
- (Optional) GTKWave for viewing waveforms

### Simulation (Icarus Verilog example)

```bash
iverilog -g2012 -o uart_sim transmitter.v receiver.v uart_top.v your_testbench.v
vvp uart_sim
```

No testbench is checked into the repo yet.

## Status

Transmitter, receiver, and top-level wiring are implemented and have been simulated together successfully. Testbenches are not yet checked in.

## License

TBD
