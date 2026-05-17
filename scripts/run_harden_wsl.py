#!/usr/bin/env python3
"""Write and execute /tmp/harden_local.sh in WSL (LF line endings)."""
import os
import subprocess
import sys

SCRIPT = r"""#!/usr/bin/env bash
set -euo pipefail
export PATH="/mnt/wsl/docker-desktop/cli-tools/usr/bin:$PATH"
ROOT="/mnt/c/Users/zunmun/Documents/Stuff/Workspace/2026/hackadayeurope/tinytapeout/ttsky26b-hackin7-hackaday2026"
cd "$ROOT"
export PDK_ROOT="$HOME/ttsetup/pdk"
export PDK=sky130A
LOG="$ROOT/runs/local_harden.log"
mkdir -p runs
exec > >(tee "$LOG") 2>&1
echo "=== Tiny Tapeout local harden ==="
date
docker info >/dev/null
if [ ! -d tt/.git ]; then
  git clone --depth 1 https://github.com/TinyTapeout/tt-support-tools tt
fi
if [ ! -d "$HOME/ttsetup/venv" ]; then
  python3 -m venv "$HOME/ttsetup/venv"
fi
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
echo "=== done ==="
find runs/wokwi -name '*.gds' 2>/dev/null | head -5
date
"""

path = "/tmp/harden_local.sh"
with open(path, "w", newline="\n") as f:
    f.write(SCRIPT)
os.chmod(path, 0o755)
print(f"Wrote {path}, starting harden...")
sys.stdout.flush()
subprocess.check_call(["sg", "docker", "-c", f"bash {path}"])
