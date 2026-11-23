#!/usr/bin/env bash
set -euo pipefail

ROOT="$HOME/Prometheus-Lite"
cd "$ROOT"

usage() {
  echo "Usage: $0 <program.asm> [--port /dev/ttyUSB0] [--force-fpga] [--rebuild]"
  exit 1
}

[[ $# -ge 1 ]] || usage

SOURCE="$1"
shift

PORT=""
FORCE_FPGA=false
REBUILD=false

while [[ $# -gt 0 ]]; do
  case "$1" in
  --port)
    [[ $# -ge 2 ]] || usage
    PORT="$2"
    shift 2
    ;;
  --force-fpga)
    FORCE_FPGA=true
    shift
    ;;
  --rebuild)
    REBUILD=true
    shift
    ;;
  *)
    usage
    ;;
  esac
done

[[ -f "$SOURCE" ]] || {
  echo "Assembly file not found: $SOURCE" >&2
  exit 1
}

mkdir -p build/programs

BINARY="$ROOT/build/programs/current.bin"
BITSTREAM="$ROOT/build/icepi/cpu.bit"
UART_SCRIPT="$ROOT/scripts/icepi-uart.py"

echo "[1/4] Assembling $SOURCE"
python3 assembler/assembler.py "$SOURCE" "$BINARY"

SIZE=$(stat -c%s "$BINARY")
if ((SIZE < 1 || SIZE > 3072)); then
  echo "Invalid program size: $SIZE bytes (maximum 3072)" >&2
  exit 1
fi

# Find the USB UART device.
find_port() {
  if [[ -n "$PORT" ]]; then
    [[ -e "$PORT" ]] && return 0
    return 1
  fi

  local candidate

  for candidate in /dev/serial/by-id/* /dev/ttyUSB*; do
    [[ -e "$candidate" ]] || continue
    PORT="$candidate"
    return 0
  done

  return 1
}

# Test whether the Prometheus UART protocol responds.
probe() {
  python3 "$UART_SCRIPT" "$PORT" status \
    >/dev/null 2>&1
}

echo "[2/4] Detecting iCEPi Zero UART"

find_port || {
  echo "No USB UART device detected." >&2
  exit 1
}

echo "Using $PORT"

NEED_FPGA=false

if [[ "$FORCE_FPGA" == true ]]; then
  NEED_FPGA=true
elif probe; then
  echo "Prometheus Lite UART bridge responded."
else
  echo "No Prometheus Lite response detected."
  NEED_FPGA=true
fi

# Check whether an existing bitstream needs rebuilding.
if [[ "$REBUILD" == true || ! -s "$BITSTREAM" ]]; then
  echo "[3/4] Building Prometheus Lite bitstream"
  bash scripts/build-icepi-trace.sh
elif find src fpga/icepi-zero scripts \
  -type f \
  \( -name '*.v' -o -name '*.ys' -o -name '*.lpf' \
  -o -name 'pack-icepi.sh' -o -name 'build-icepi-trace.sh' \) \
  -newer "$BITSTREAM" | grep -q .; then
  echo "[3/4] FPGA sources changed; rebuilding"
  bash scripts/build-icepi-trace.sh
else
  echo "[3/4] Existing bitstream available"
fi

if [[ "$NEED_FPGA" == true || "$REBUILD" == true ]]; then
  echo "Configuring FPGA..."

  openFPGALoader -b icepi-zero "$BITSTREAM"

  # Give the bridge time to become responsive.
  READY=false

  for attempt in {1..10}; do
    sleep 0.5
    if find_port && probe; then
      READY=true
      break
    fi
  done

  if [[ "$READY" != true ]]; then
    echo "FPGA configured but UART bridge did not respond." >&2
    echo "Check the USB UART port and reset button." >&2
    exit 1
  fi
else
  echo "FPGA already responds; skipping configuration."
fi

echo "[4/4] Loading program into Prometheus Lite"
python3 "$UART_SCRIPT" "$PORT" load "$BINARY"

echo
echo "Success!"
echo "Program: $SOURCE"
echo "Size: $SIZE / 3072 bytes"
echo "Serial: $PORT"
echo "CPU started."
