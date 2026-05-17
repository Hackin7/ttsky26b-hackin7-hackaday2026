# Run Verilator lint + cocotb tests via WSL (matches GitHub Actions tooling).
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot

Write-Host "=== Verilator + Icarus (lint.sh) ===" -ForegroundColor Cyan
wsl -e bash -lc "cd '$(wsl wslpath -a $Root)' && bash scripts/lint.sh"

Write-Host "=== Cocotb tests (test workflow) ===" -ForegroundColor Cyan
wsl -e bash -lc @"
set -e
cd '$(wsl wslpath -a $Root)'
if [ ! -d .venv ]; then python3 -m venv .venv && .venv/bin/pip install -q -r test/requirements.txt; fi
cd test
export PATH="../.venv/bin:`$PATH"
make clean
make
! grep failure results.xml
echo 'Tests passed.'
"@

Write-Host "All local checks passed." -ForegroundColor Green
