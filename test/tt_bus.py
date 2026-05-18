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
    # Allow FSM to finish after din_valid
    await ClockCycles(dut.clk, settle_cycles)


async def read_result_byte(dut, byte_sel: int) -> int:
    """Drive result-read phase for one byte. byte_sel 0..3 (little-endian).

    Asserts ui_in[7]=1 with ui_in[6:5]=byte_sel for one rising edge,
    samples uo_out, then clears ui_in.
    """
    dut.ui_in.value = (1 << 7) | ((byte_sel & 3) << 5)
    dut.uio_in.value = 0
    await RisingEdge(dut.clk)
    result = int(dut.uo_out.value)
    dut.ui_in.value = 0
    await RisingEdge(dut.clk)
    return result


async def read_result32(dut) -> int:
    """Read full 32-bit result_reg via 4-cycle uo_out port read.

    Requires result_valid (uo_out[0] in idle mode) to be set first.
    Assembles bytes little-endian: byte_sel 0 = LSB, 3 = MSB.
    """
    idle_uo = int(dut.uo_out.value)
    if not (idle_uo & 1):
        raise RuntimeError("result_valid not set (uo_out[0]=0); cannot read result")
    val = 0
    for sel in range(4):
        b = await read_result_byte(dut, sel)
        val |= (b & 0xFF) << (8 * sel)
    return val


async def read_loop_count_a(dut) -> int:
    """Read part-A loop counter via 4-cycle uo_out port read (works in RTL and GL)."""
    return await read_result32(dut)
