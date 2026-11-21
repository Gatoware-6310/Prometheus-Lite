#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

mkdir -p build/icepi
python3 - <<'PYTHON'
from pathlib import Path

program = Path("fpga/icepi-zero/program.hex")
image = ["xx"] * 3072
address = 0
for line in program.read_text().splitlines():
    for token in line.split("//", 1)[0].split():
        if token.startswith("@"):
            address = int(token[1:], 16)
        else:
            image[address] = token
            address += 1
for bank in range(3):
    Path(f"build/icepi/bank{bank}.hex").write_text("\n".join(image[bank::3]) + "\n")
PYTHON
yosys -ql build/icepi/synth.log fpga/icepi-zero/trace.ys
nextpnr-ecp5 --25k --package CABGA256 --freq 50 \
    --json build/icepi/cpu.json --lpf fpga/icepi-zero/icepi-zero.lpf \
    --textcfg build/icepi/cpu.config --report build/icepi/timing.json \
    --log build/icepi/route.log
bash scripts/pack-icepi.sh
