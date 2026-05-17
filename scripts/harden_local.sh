#!/usr/bin/env bash
set -euo pipefail

export DOCKER="${DOCKER:-/mnt/wsl/docker-desktop/cli-tools/usr/bin/docker}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

export PDK_ROOT="${PDK_ROOT:-$HOME/ttsetup/pdk}"
export PDK="${PDK:-sky130A}"

LOG="$ROOT/runs/local_harden.log"
mkdir -p runs
exec > >(tee "$LOG") 2>&1

echo "=== Tiny Tapeout local harden ==="
echo "Project: $ROOT"
date

if ! "$DOCKER" info >/dev/null 2>&1; then
  echo "ERROR: Docker daemon not reachable."
  exit 1
fi

if [ ! -d tt/.git ]; then
  echo "Cloning tt-support-tools..."
  git clone --depth 1 https://github.com/TinyTapeout/tt-support-tools tt
fi

if [ ! -d "$HOME/ttsetup/venv" ]; then
  python3 -m venv "$HOME/ttsetup/venv"
fi
# shellcheck disable=SC1091
source "$HOME/ttsetup/venv/bin/activate"

pip install -q -U pip
pip install -q -r tt/requirements.txt
pip install -q librelane==3.0.0

echo "=== create-user-config ==="
./tt/tt_tool.py --create-user-config

echo "=== harden ==="
./tt/tt_tool.py --harden

echo "=== print-stats ==="
./tt/tt_tool.py --print-stats || true

echo "=== SUCCESS ==="
find runs/wokwi -name '*.gds' 2>/dev/null | head -10
date
