# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0
"""
Software golden model for the Hardcaml coprocessor (part A).

Counts how many times the dial lands on 0 after each step:
  position = (position + value) % 100
  if position == 0: count += 1

This matches RTL calc_num_loops_a behavior on input_sample.txt (3).
The proto/1/sol_b.py wrap-around loop model differs (6) and is not used here.
"""

from __future__ import annotations

import sys
from pathlib import Path


def parse_line(line: str) -> int:
    line = line.strip()
    if not line:
        raise ValueError("empty line")
    sign = 1 if line[0] == "R" else -1
    return sign * int(line[1:])


def step(position: int, value: int) -> tuple[int, int]:
    """Apply one dial step; return (new_position, no_loops)."""
    new_position = (position + value) % 100
    no_loops = 1 if new_position == 0 else 0
    return new_position, no_loops


def expected_count(path: str | Path, start: int = 50) -> int:
    position = start
    total = 0
    with open(path) as f:
        for line in f:
            if not line.strip():
                continue
            value = parse_line(line)
            position, no_loops = step(position, value)
            total += no_loops
    return total


# Frozen reference for fixtures/input_sample.txt
EXPECTED_INPUT_SAMPLE = 3


if __name__ == "__main__":
    fixture = (
        Path(sys.argv[1])
        if len(sys.argv) > 1
        else Path(__file__).parent / "fixtures" / "input_sample.txt"
    )
    print(expected_count(fixture))
