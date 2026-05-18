# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0
"""Cocotb helpers for tt_um_hackin7_coprocessor pin protocol."""

from __future__ import annotations

from cocotb.triggers import ClockCycles, RisingEdge


def pack_step(value: int) -> bytes:
    """16-byte frame: signed 32-bit step in din[31:0] (strobe byte 0 -> din[7:0])."""
    word = (value & 0xFFFFFFFF).to_bytes(4, byteorder="little", signed=False)
    return word + b"\x00" * 12


async def reset_dut(dut, cycles: int = 10) -> None:
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, cycles)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)


async def load_bytes(dut, data: bytes) -> None:
    assert len(data) == 16
    for byte in data:
        dut.uio_in.value = byte
        dut.ui_in.value = 0b1  # BYTE_STROBE
        await RisingEdge(dut.clk)
        dut.ui_in.value = 0
        await RisingEdge(dut.clk)


async def pulse_compute(dut, control: int = 0) -> None:
    dut.ui_in.value = ((control & 0x1F) << 2) | 0b10  # COMPUTE + control[4:0]
    await RisingEdge(dut.clk)
    dut.ui_in.value = 0
    await RisingEdge(dut.clk)


async def run_step(dut, value: int, control: int = 0, settle_cycles: int = 32) -> None:
    await load_bytes(dut, pack_step(value))
    await pulse_compute(dut, control)
    # Allow FSM to finish after din_valid (dout_valid is combinatorial with din_valid)
    await ClockCycles(dut.clk, settle_cycles)


def _try_int(signal) -> int | None:
    try:
        return int(signal.value)
    except (AttributeError, ValueError):
        return None


def read_loop_count_a(dut) -> int:
    """Read part-A loop counter (32-bit). Uses tb probes, then hierarchy, then uo_out."""
    for path in (
        lambda: dut.dbg_calc_num_loops_a,
        lambda: dut.dbg_result_reg,
        lambda: dut.user_project.u_coprocessor.calc_num_loops_a,
        lambda: dut.user_project.result_reg,
    ):
        try:
            val = _try_int(path())
            if val is not None:
                return val
        except AttributeError:
            continue

    # Pin fallback: uo_out = {result_reg[6:0], result_valid} (valid for counts < 128)
    uo = int(dut.uo_out.value)
    if uo & 1:
        return (uo >> 1) & 0x7F

    raise AttributeError(
        "Could not read loop count: add dbg_* probes in tb.v or assert RESULT_VALID on uo_out[0]"
    )
