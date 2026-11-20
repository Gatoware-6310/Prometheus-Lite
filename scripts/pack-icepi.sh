#!/usr/bin/env bash
# Pack an existing nextpnr configuration with a pinned upstream Trellis database.
set -euo pipefail
cd "$(dirname "$0")/.."

revision=9754ff473bfaa1e6edfaf57ce13bd447c76a88f6
database="$PWD/build/trellis-db"
output=build/icepi
test -s "$output/cpu.config"
if [[ ! -d "$database" ]]; then
    git clone https://github.com/YosysHQ/prjtrellis-db.git "$database"
    git -C "$database" checkout --detach "$revision"
fi
if [[ "$(git -C "$database" rev-parse HEAD)" != "$revision" ]] ||
   [[ -n "$(git -C "$database" status --porcelain)" ]]; then
    echo "Expected a clean Trellis database at $revision in $database" >&2
    exit 1
fi

# Check upstream metadata; never patch geometry or override the bitstream ID.
python3 - "$database/devices.json" <<'PY'
import json
import sys
with open(sys.argv[1]) as source:
    device = json.load(source)['families']['ECP5']['devices']['LFE5U-25F']
assert int(device['idcode'], 0) == 0x41111043
assert (device['frames'], device['bits_per_frame']) == (7562, 592)
assert (device['row_bias'], device['col_bias']) == (0, 0)
assert 'caBGA256' in device['packages']
PY

ecppack --db "$database" "$output/cpu.config" "$output/cpu.bit"
ecpunpack --db "$database" "$output/cpu.bit" "$output/cpu.unpacked.config" \
    > "$output/cpu.unpack.log" 2>&1
cat "$output/cpu.unpack.log"
python3 - "$output/cpu.unpacked.config" <<'PY'
import sys
with open(sys.argv[1]) as source:
    assert source.readline().strip() == '.device LFE5U-25F'
PY
ecppack --db "$database" "$output/cpu.unpacked.config" "$output/cpu.repacked.bit"
cmp "$output/cpu.bit" "$output/cpu.repacked.bit"
sha256sum "$output/cpu.bit"
