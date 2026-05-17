#!/usr/bin/env python3
"""Generate bitmap_rom.v (3-bit color index per pixel) from Backpack.png."""

from pathlib import Path

from PIL import Image

# 32x32 on 1x1 (OpenLane measured 155.2% util at 48x48 on 1x1, run 25984904707).
LOGO_SIZE = 32

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

    size = LOGO_SIZE
    groups_per_row = size // 8
    bytes_per_row = groups_per_row * 3

    img = Image.open(src).convert("RGBA")
    try:
        resample = Image.Resampling.LANCZOS
    except AttributeError:
        resample = Image.LANCZOS
    img = img.resize((size, size), resample)

    indices = []
    for y in range(size):
        row = []
        for x in range(size):
            row.append(nearest_index(*img.getpixel((x, y))))
        indices.append(row)

    mem = [0] * (size * bytes_per_row)
    for y in range(size):
        for gx in range(groups_per_row):
            packed = 0
            for px in range(8):
                packed |= (indices[y][gx * 8 + px] & 7) << (px * 3)
            base = y * bytes_per_row + gx * 3
            mem[base] = packed & 0xFF
            mem[base + 1] = (packed >> 8) & 0xFF
            mem[base + 2] = (packed >> 16) & 0xFF

    coord_bits = (size - 1).bit_length()
    x_msb = coord_bits - 1
    x_grp_hi = x_msb
    x_grp_lo = 3
    max_group = size * groups_per_row - 1
    base_bits = (max_group * 3 + 2).bit_length()
    g_bits = (max_group).bit_length()

    if groups_per_row == (1 << (coord_bits - 3)):
        group_lines = [
            f"  wire [{g_bits - 1}:0] group = {{y[{x_msb}:0], x[{x_grp_hi}:{x_grp_lo}]}};",
        ]
    elif groups_per_row == 6:
        group_lines = [
            "  wire [7:0] row_off = ({y[5:0], 1'b0} + {y[5:0], 2'b00});",
            "  wire [8:0] group = row_off + {6'b0, x[5:3]};",
        ]
    else:
        group_lines = [
            f"  wire [{g_bits - 1}:0] group = y * {groups_per_row} + {{3'b0, x[2:0]}};",
        ]

    lines = [
        "/*",
        " * Copyright (c) 2024 Tiny Tapeout LTD",
        " * SPDX-License-Identifier: Apache-2.0",
        f" * {size}x{size} 3-bit color bitmap from Backpack.png",
        " */",
        "",
        "`default_nettype none",
        "",
        "module bitmap_rom (",
        f"    input wire [{coord_bits - 1}:0] x,",
        f"    input wire [{coord_bits - 1}:0] y,",
        "    output wire [2:0] color_idx",
        ");",
        "",
        f"  reg [7:0] mem[{len(mem) - 1}:0];",
        "  initial begin",
    ]
    for i, val in enumerate(mem):
        lines.append(f"    mem[{i}] = 8'h{val:02x};")
    lines += ["  end", ""] + group_lines + [
        f"  wire [{base_bits - 1}:0] base = {{1'b0, group}} + {{group, 1'b0}};",
        "  wire [23:0] pix_word = {mem[base + 2], mem[base + 1], mem[base]};",
        "  assign color_idx = pix_word[x[2:0] * 3 +: 3];",
        "",
        "endmodule",
        "",
    ]
    out.write_text("\n".join(lines), encoding="utf-8")
    colored = sum(sum(1 for v in row if v) for row in indices)
    print(f"Wrote {out} ({size}x{size}, {colored} colored pixels, {len(mem)} bytes)")


if __name__ == "__main__":
    main()
