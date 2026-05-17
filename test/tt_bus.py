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


def read_loop_count_a(dut) -> int:
    return int(dut.user_project.u_coprocessor.calc_num_loops_a.value)
