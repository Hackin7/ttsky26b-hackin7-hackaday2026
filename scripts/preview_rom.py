#!/usr/bin/env python3
"""Decode bitmap_rom.v to PNG to verify packing matches hardware."""

import re
from pathlib import Path

from PIL import Image

SIZE = 24
ROOT = Path(__file__).resolve().parents[1]
ROM = ROOT / "src" / "bitmap_rom.v"
OUT = ROOT / "scripts" / "rom_preview.png"

PALETTE = [
    (0, 0, 0),
    (0, 0, 0),
    (120, 120, 120),
    (150, 95, 55),
    (55, 140, 65),
    (70, 150, 255),
    (255, 255, 255),
    (40, 40, 40),
]

text = ROM.read_text()
mem = [int(m.group(2), 16) for m in re.finditer(r"mem\[(\d+)\] = 8'h([0-9a-f]+)", text)]

img = Image.new("RGB", (SIZE, SIZE), (0, 0, 0))
for y in range(SIZE):
    for x in range(SIZE):
        groups_per_row = SIZE // 8
        group = y * groups_per_row + (x >> 3)
        base = group * 3
        pix_word = (mem[base + 2] << 16) | (mem[base + 1] << 8) | mem[base]
        idx = (pix_word >> ((x & 7) * 3)) & 7
        if idx:
            img.putpixel((x, y), PALETTE[idx])

img.save(OUT)
print(f"Wrote {OUT}")
