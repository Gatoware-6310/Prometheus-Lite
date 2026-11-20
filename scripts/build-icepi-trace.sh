#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

mkdir -p build/icepi
yosys -ql build/icepi/synth.log fpga/icepi-zero/trace.ys
nextpnr-ecp5 --25k --package CABGA256 --freq 50 \
    --json build/icepi/cpu.json --lpf fpga/icepi-zero/icepi-zero.lpf \
    --textcfg build/icepi/cpu.config --report build/icepi/timing.json \
    --log build/icepi/route.log
bash scripts/pack-icepi.sh
