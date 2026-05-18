# Coprocessor simulation tests

RTL tests use [cocotb](https://docs.cocotb.org/) + Icarus Verilog.

- **Part A** (`golden_aoc.py`): after each step, `position = (position + value) % 100`; increment when the dial **lands** on `0`. Sample expects **3**.
- **Part B** (`golden_aoc_b.py`): count every time the dial points at `0` **during** each rotation (unit steps mod 100). Sample expects **6**. RTL mux: `control[3]=1` (`CONTROL_PART_B = 0b01100`, matches badge `part_b_enable(1)` after `setup()`).

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
python3 golden_aoc.py fixtures/input_sample.txt
# prints: 3
python3 golden_aoc_b.py fixtures/input_sample.txt
# prints: 6
```

## What is tested

Both cocotb tests drive `tt_um_hackin7_coprocessor` through the Tiny Tapeout pin protocol:

1. Reset, then three zero steps (pipeline priming, same as badge `solve.py`)
2. Each line in `fixtures/input_sample.txt` as one 16-byte frame + COMPUTE pulse
3. Two zero steps to drain the pipeline
4. 4-cycle `uo_out` port read of `result_reg`

| Test | Control | Golden | Sample expected |
|------|---------|--------|-----------------|
| `test_input_sample_matches_golden` | `CONTROL_PART_A` (`0b00100`) | `golden_aoc` | 3 |
| `test_input_sample_part_b_matches_golden` | `CONTROL_PART_B` (`0b01100`) | `golden_aoc_b` | 6 |

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
