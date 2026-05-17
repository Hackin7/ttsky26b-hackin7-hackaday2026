# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

from pathlib import Path

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

from golden_aoc import EXPECTED_INPUT_SAMPLE, expected_count, parse_line
from tt_bus import read_loop_count_a, reset_dut, run_step

# Badge solve.py ends setup with set_mode(0,0,1) -> control[2]=1 (position / stream mode)
CONTROL_PART_A = 0b00100

FIXTURE = Path(__file__).parent / "fixtures" / "input_sample.txt"


def test_golden_self_check() -> None:
    """Pure Python: golden model runs and matches frozen reference."""
    assert expected_count(FIXTURE) == EXPECTED_INPUT_SAMPLE


@cocotb.test()
async def test_input_sample_matches_golden(dut):
    expected = expected_count(FIXTURE)
    assert expected == EXPECTED_INPUT_SAMPLE
    dut._log.info("Golden expected loop count: %d", expected)

    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    await reset_dut(dut)

    for _ in range(3):
        await run_step(dut, 0, control=CONTROL_PART_A, settle_cycles=64)

    with open(FIXTURE) as f:
        for line in f:
            if not line.strip():
                continue
            value = parse_line(line)
            dut._log.info("Step value=%d", value)
            await run_step(dut, value, control=CONTROL_PART_A, settle_cycles=64)

    await run_step(dut, 0, control=CONTROL_PART_A, settle_cycles=64)
    await run_step(dut, 0, control=CONTROL_PART_A, settle_cycles=64)

    await ClockCycles(dut.clk, 64)

    actual = read_loop_count_a(dut)
    dut._log.info("RTL calc_num_loops_a=%d, golden=%d", actual, expected)
    assert actual == expected, f"RTL {actual} != golden {expected}"
