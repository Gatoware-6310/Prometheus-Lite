import argparse
from decimal import Decimal
from pathlib import Path
import re


def fix_power_ports(path):
    lef = path.read_text()
    height = Decimal(re.search(r"^  SIZE [\d.]+ BY ([\d.]+) ;$", lef, re.M)[1])
    internal = []

    for pin in ("VPWR", "VGND"):
        block = re.search(rf"^  PIN {pin}\n(.*?)^  END {pin}$", lef, re.M | re.S)
        body = block[1]
        external = 0

        def classify(port):
            nonlocal external
            bottom, top = map(Decimal, port.group(2, 3))
            if bottom <= 10 and height - top <= 10:
                external += 1
                return port[0]
            if bottom > 10 and height - top > 10:
                internal.append(port[1])
                return ""
            return port[0]

        fixed = re.sub(
            r"^    PORT\n      LAYER Metal4 ;\n"
            r"        (RECT [\d.]+ ([\d.]+) [\d.]+ ([\d.]+) ;)\n    END\n",
            classify, body, flags=re.M,
        )
        if not external:
            raise ValueError(f"{pin} has no full-height Metal4 strap")
        lef = lef[:block.start(1)] + fixed + lef[block.end(1):]

    if internal:
        # Keep the actual metal blocked for routing while hiding internal ports.
        obs = re.search(r"^  OBS\n.*?^      LAYER Metal4 ;\n", lef, re.M | re.S)
        rects = "".join(f"        {rect}\n" for rect in internal)
        lef = lef[:obs.end()] + rects + lef[obs.end():]
        path.write_text(lef)

    print(f"{path}: moved {len(internal)} internal straps to Metal4 OBS")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("lef", type=Path)
    fix_power_ports(parser.parse_args().lef)
