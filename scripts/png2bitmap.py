#!/usr/bin/env python3
"""Generate bitmap_rom.v (3-bit color index per pixel) from Backpack.png."""

from pathlib import Path

from PIL import Image

SIZE = 128

# Index 0 = transparent; 1-7 match palette.v
PALETTE = [
    None,
    (0, 0, 0),
    (120, 120, 120),
    (150, 95, 55),
    (55, 140, 65),
    (70, 150, 255),
    (255, 255, 255),
    (40, 40, 40),
]


def nearest_index(r: int, g: int, b: int, a: int) -> int:
    if a < 32 or max(r, g, b) < 40:
        return 0
    best, best_d = 1, 1 << 30
    for i, rgb in enumerate(PALETTE):
        if rgb is None:
            continue
        pr, pg, pb = rgb
        d = (r - pr) ** 2 + (g - pg) ** 2 + (b - pb) ** 2
        if d < best_d:
            best_d, best = d, i
    return best


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    src = root.parent / "Backpack.png"
    if not src.exists():
        src = root / "docs" / "Backpack.png"
    out = root / "src" / "bitmap_rom.v"

    img = Image.open(src).convert("RGBA")
    try:
        resample = Image.Resampling.LANCZOS
    except AttributeError:
        resample = Image.LANCZOS
    img = img.resize((SIZE, SIZE), resample)

    indices = []
    for y in range(SIZE):
        row = []
        for x in range(SIZE):
            row.append(nearest_index(*img.getpixel((x, y))))
        indices.append(row)

    mem = [0] * (SIZE * 48)
    for y in range(SIZE):
        for gx in range(16):
            packed = 0
            for px in range(8):
                packed |= (indices[y][gx * 8 + px] & 7) << (px * 3)
            base = y * 48 + gx * 3
            mem[base] = packed & 0xFF
            mem[base + 1] = (packed >> 8) & 0xFF
            mem[base + 2] = (packed >> 16) & 0xFF

    lines = [
        "/*",
        " * Copyright (c) 2024 Tiny Tapeout LTD",
        " * SPDX-License-Identifier: Apache-2.0",
        " * 3-bit color index per pixel, generated from Backpack.png",
        " */",
        "",
        "`default_nettype none",
        "",
        "module bitmap_rom (",
        "    input wire [6:0] x,",
        "    input wire [6:0] y,",
        "    output wire [2:0] color_idx",
        ");",
        "",
        f"  reg [7:0] mem[{len(mem) - 1}:0];",
        "  initial begin",
    ]
    for i, val in enumerate(mem):
        lines.append(f"    mem[{i}] = 8'h{val:02x};")
    lines += [
        "  end",
        "",
        "  wire [10:0] group = {y[6:0], x[6:3]};",
        "  wire [12:0] base = group + group + group;",
        "  wire [23:0] pix_word = {mem[base + 2], mem[base + 1], mem[base]};",
        "  assign color_idx = pix_word[x[2:0] * 3 +: 3];",
        "",
        "endmodule",
        "",
    ]
    out.write_text("\n".join(lines), encoding="utf-8")
    colored = sum(sum(1 for v in row if v) for row in indices)
    print(f"Wrote {out} ({colored} colored pixels, {len(mem)} bytes)")


if __name__ == "__main__":
    main()
