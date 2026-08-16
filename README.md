# UART Communication Protocol — Verilog

Implementation of a UART (Universal Asynchronous Receiver/Transmitter) in Verilog, including transmitter, receiver, and testbenches for simulation.

## Overview

UART is an asynchronous serial communication protocol used for point-to-point data exchange without a shared clock. This project implements:

- **UART Transmitter (TX)** — serializes parallel data and sends it over a single data line
- **UART Receiver (RX)** — deserializes incoming serial data back into parallel form
- **Baud Rate Generator** — produces the sampling clock for a configurable baud rate
- **Testbench(es)** — verify TX/RX functionality in simulation

## Frame Format

```
 Idle | Start | D0 D1 D2 D3 D4 D5 D6 D7 | Parity (optional) | Stop | Idle
  1   |   0   |     8 data bits (LSB first)     |    0/1   |  1   |  1
```

- **Start bit**: 1 bit, always `0`
- **Data bits**: typically 8 bits, LSB first
- **Parity bit**: optional (none / even / odd)
- **Stop bit(s)**: 1 or 2 bits, always `1`
- Line idles `HIGH` between frames

## Project Structure

```
uart-protocol-verilog/
├── rtl/                # Synthesizable design files
│   ├── uart_tx.v
│   ├── uart_rx.v
│   └── baud_gen.v
├── tb/                 # Testbenches
│   ├── uart_tx_tb.v
│   └── uart_rx_tb.v
├── sim/                # Simulation scripts / waveform output
└── README.md
```

## Parameters

| Parameter     | Description                          | Default |
|---------------|---------------------------------------|---------|
| `CLK_FREQ`    | System clock frequency (Hz)           | 50 MHz  |
| `BAUD_RATE`   | Desired baud rate (bps)               | 9600    |
| `DATA_BITS`   | Number of data bits per frame         | 8       |
| `STOP_BITS`   | Number of stop bits                   | 1       |
| `PARITY`      | Parity mode (`NONE` / `EVEN` / `ODD`) | NONE    |

## Getting Started

### Prerequisites

- A Verilog simulator (e.g., Icarus Verilog, ModelSim, Vivado Simulator)
- (Optional) GTKWave for viewing waveforms

### Simulation (Icarus Verilog example)

```bash
iverilog -o uart_tx_sim rtl/uart_tx.v tb/uart_tx_tb.v
vvp uart_tx_sim
gtkwave uart_tx.vcd
```

## Status

🚧 Work in progress — module implementations coming soon.

## License

TBD
