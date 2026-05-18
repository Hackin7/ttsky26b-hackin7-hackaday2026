# Coprocessor simulation tests

RTL tests use [cocotb](https://docs.cocotb.org/) + Icarus Verilog. The software golden model is in `golden_aoc.py`: after each step it applies `position = (position + value) % 100` and increments when the dial lands on `0`. That matches what `calc_num_loops_a` reports in simulation (not the separate wrap-count rules in `proto/1/sol_b.py`).

## Setup

```bash
cd test
pip install -r requirements.txt
# Linux / WSL / CI:
sudo apt-get install -y iverilog
```

## Run tests

```bash
make clean && make -B
```

Pure-Python golden check (no simulator):

```bash
python golden_aoc.py fixtures/input_sample.txt
# prints: 3
```

## What is tested

`test_input_sample_matches_golden` drives `tt_um_hackin7_coprocessor` through the Tiny Tapeout pin protocol:

1. Reset, then three zero steps (pipeline priming, same as badge `solve.py`)
2. Each line in `fixtures/input_sample.txt` as one 16-byte frame + COMPUTE pulse
3. Two zero steps to drain the pipeline
4. Compare `calc_num_loops_a` (part A, `control=0`) to `golden_aoc.expected_count()`

Full 32-bit result is read via 4-cycle `uo_out` port read: host asserts `ui_in[7]=1` with `ui_in[6:5]=byte_sel` (0–3, little-endian) for one clock per byte, samples `uo_out`. Works identically in RTL and gate-level simulation (no hierarchy probes needed).

## Waveforms

```bash
gtkwave tb.fst tb.gtkw
# or: surfer tb.fst
```

VCD instead of FST: change `$dumpfile` in `tb.v` to `tb.vcd`, then `make -B FST=`.

## Gate-level (after harden)

```bash
export PDK_ROOT=~/ttsetup/pdk
TOP=$(cd .. && ./tt/tt_tool.py --print-top-module)
cp ../runs/wokwi/final/verilog/gl/${TOP}.v gate_level_netlist.v
make clean && make -B GATES=yes
```
