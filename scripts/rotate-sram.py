from decimal import Decimal
from pathlib import Path
import re

import klayout.db as kdb


name = "gf180mcu_ocd_ip_sram__sram1024x8m8wm1"
root = Path(__file__).resolve().parents[1]
stem = root / "build/asic-memory/ocd/cells" / name / name
lef = stem.with_suffix(".lef").read_text()
size = re.search(r"SIZE ([\d.]+) BY ([\d.]+) ;", lef)
width, height = map(Decimal, size.groups())

layout = kdb.Layout()
layout.read(str(stem.with_suffix(".gds")))
top = layout.cell(name)
if top.dbbox() != kdb.DBox(0, 0, float(width), float(height)):
    raise ValueError("Original GDS and LEF outlines differ")

# Rotate around the lower left, then move the new outline to the origin.
top.transform(kdb.DTrans(kdb.DTrans.R90, float(height), 0))
if top.dbbox() != kdb.DBox(0, 0, float(height), float(width)):
    raise ValueError("Unexpected rotated GDS outline")
layout.write(str(stem.with_suffix(".rotated.gds")))


def rotate_rect(match):
    x1, y1, x2, y2 = map(Decimal, match.groups())
    return f"RECT {height - y2} {x1} {height - y1} {x2} ;"


# Rotate the LEF pins and obstructions to match GDS.
lef = lef.replace(size[0], f"SIZE {height} BY {width} ;")
lef = re.sub(r"RECT ([-.\d]+) ([-.\d]+) ([-.\d]+) ([-.\d]+)\s*;", rotate_rect, lef)
stem.with_suffix(".rotated.lef").write_text(lef)
