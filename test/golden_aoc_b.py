# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0
"""
Software golden model for the Hardcaml coprocessor (part B).

Counts every time the dial points at 0 during each rotation (unit steps, mod 100),
not only when it lands on 0 after the click. Matches calc_num_loops_b on input_sample.txt (6).
"""

from __future__ import annotations

import sys
from pathlib import Path

from golden_aoc import parse_line


def step_b(position: int, value: int) -> tuple[int, int]:
    """Apply one dial click; return (new_position, zero_crossings_during_move)."""
    count = 0
    step_dir = 1 if value > 0 else -1
    for _ in range(abs(value)):
        position = (position + step_dir) % 100
        if position == 0:
            count += 1
    return position, count


def expected_count_b(path: str | Path, start: int = 50) -> int:
    position = start
    total = 0
    with open(path) as f:
        for line in f:
            if not line.strip():
                continue
            value = parse_line(line)
            position, crossings = step_b(position, value)
            total += crossings
    return total


# Frozen reference for fixtures/input_sample.txt
EXPECTED_INPUT_SAMPLE_B = 6


if __name__ == "__main__":
    fixture = (
        Path(sys.argv[1])
        if len(sys.argv) > 1
        else Path(__file__).parent / "fixtures" / "input_sample.txt"
    )
    print(expected_count_b(fixture))
