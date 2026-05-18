# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

from pathlib import Path

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

from golden_aoc import EXPECTED_INPUT_SAMPLE, expected_count, parse_line
from golden_aoc_b import EXPECTED_INPUT_SAMPLE_B, expected_count_b
from tt_bus import (
    CONTROL_PART_A,
    CONTROL_PART_B,
    read_loop_count_a,
    read_result32,
    reset_dut,
    run_step,
)

FIXTURE = Path(__file__).parent / "fixtures" / "input_sample.txt"


def test_golden_self_check() -> None:
    """Pure Python: golden model runs and matches frozen reference."""
    assert expected_count(FIXTURE) == EXPECTED_INPUT_SAMPLE


def test_golden_b_self_check() -> None:
    """Pure Python: part B golden matches frozen reference."""
    assert expected_count_b(FIXTURE) == EXPECTED_INPUT_SAMPLE_B


async def _run_input_sample(dut, control: int) -> int:
    """Drive fixture with given control on every step; return port-read result."""
    for _ in range(3):
        await run_step(dut, 0, control=control, settle_cycles=64)

    with open(FIXTURE) as f:
        for line in f:
            if not line.strip():
                continue
            value = parse_line(line)
            dut._log.info("Step value=%d", value)
            await run_step(dut, value, control=control, settle_cycles=64)

    await run_step(dut, 0, control=control, settle_cycles=64)
    await run_step(dut, 0, control=control, settle_cycles=64)
    await ClockCycles(dut.clk, 64)
    return await read_result32(dut)


@cocotb.test()
async def test_input_sample_matches_golden(dut):
    expected = expected_count(FIXTURE)
    assert expected == EXPECTED_INPUT_SAMPLE
    dut._log.info("Golden expected loop count (A): %d", expected)

    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())
    await reset_dut(dut)

    actual = await _run_input_sample(dut, CONTROL_PART_A)
    dut._log.info("RTL loops_a=%d, golden=%d", actual, expected)
    assert actual == expected, f"RTL {actual} != golden {expected}"


@cocotb.test()
async def test_input_sample_part_b_matches_golden(dut):
    expected = expected_count_b(FIXTURE)
    assert expected == EXPECTED_INPUT_SAMPLE_B
    dut._log.info("Golden expected loop count (B): %d", expected)

    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())
    await reset_dut(dut)

    actual = await _run_input_sample(dut, CONTROL_PART_B)
    dut._log.info("RTL loops_b=%d, golden=%d", actual, expected)
    assert actual == expected, f"RTL {actual} != golden B {expected}"
