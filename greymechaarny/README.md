# greymechaarny — FPGA bring-up for `tt_um_hackin7_coprocessor`

ECP5 (ULX3S) build that keeps the Tiny Tapeout macro in [`../src/project.v`](../src/project.v) unchanged and reuses the UART + interconnect shell from the Advent of FPGA day-1 coprocessor design.

## Build (bitstream)

Requires Yosys, nextpnr-ecp5, ecppack.

```bash
cd greymechaarny
make
```

Output: `hackin7_coprocessor.bit`

## Simulate

```bash
cd greymechaarny
make sim
```

Runs two Icarus tests:

1. `test/tb_cocotb_match.v` — replicates the cocotb `test.py` stimulus on `tt_um` (expects `loops_a == 3`).
2. `test/tb_adapter.v` — compares `uart_tt_adapter` to a reference `tt_um` for LE (cocotb) and BE (host `write_int`) 128-bit frames.

## Architecture

- [`src/top.v`](src/top.v) — same `top` ports as the original UART FPGA design; `uart_tt_adapter` replaces the direct `coprocessor` instance.
- [`src/uart_tt_adapter.v`](src/uart_tt_adapter.v) — translates one-cycle `din_valid` + 128-bit `din` into TT byte-strobe/compute, then drives UART `dout` from `u_tt.u_coprocessor.dout`.

## Pins

See [`pinout.lpf`](pinout.lpf). `interconnect[0]` RX, `[1]` TX, `[6:2]` control, `[7]` reset (active high).

## Host

Use the existing CircuitPython [`sample.py`](https://github.com/greymechaarmy/greymechaarmy_advent_of_fpga_25) from `fpga_solutions/1/uart_coprocessor_from_hardcaml` with this bitstream path.
