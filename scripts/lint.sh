#!/usr/bin/env bash
# Mirrors Tiny Tapeout GDS verilator-lint checks (run from repo root).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

TOP="tt_um_hackin7_tbd"
SRC=(
  src/project.v
  src/hvsync_generator.v
  src/palette.v
  src/bitmap_rom.v
)

echo "=== Verilator lint (--lint-only) ==="
verilator --lint-only -Wall \
  -Wno-DECLFILENAME \
  -Wno-PINCONNECTEMPTY \
  -Wno-UNOPTFLAT \
  --top-module "$TOP" \
  "${SRC[@]}"

echo "=== Verilator lint (synthesis-style, no unused warnings) ==="
verilator --lint-only -Wall \
  -Wno-DECLFILENAME \
  -Wno-UNUSED \
  -Wno-PINCONNECTEMPTY \
  -Wno-UNOPTFLAT \
  --top-module "$TOP" \
  "${SRC[@]}"

echo "=== Icarus compile (tb + RTL) ==="
iverilog -g2012 -o /tmp/tt_um_tb.vvp \
  -I src \
  "${SRC[@]}" \
  test/tb.v

echo "All checks passed."
