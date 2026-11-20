"""Exercise the real host scan and VCD code against simulated FPGA RTL."""
import importlib.util
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[3]
spec = importlib.util.spec_from_file_location("icepi_trace", ROOT / "scripts/icepi-trace.py")
trace = importlib.util.module_from_spec(spec)
spec.loader.exec_module(trace)


class SimulatedBridge:
    def __init__(self, process):
        self.process = process

    def shift(self, cycles):
        for tms, tdi in cycles:
            self.process.stdin.write(f"{int(tms)} {tdi}\n")
            self.process.stdin.flush()
            bit = self.process.stdout.readline().strip()
            if bit not in ("0", "1"):
                raise RuntimeError(f"Unexpected simulator output: {bit!r}")
            yield int(bit)


class TraceTest(unittest.TestCase):
    def test_trigger_readout_and_vcd(self):
        with tempfile.TemporaryDirectory() as directory:
            work = Path(directory)
            simulation = work / "tap.vvp"
            subprocess.run([
                "iverilog", "-g2012", "-s", "tap_bridge", "-o", simulation,
                ROOT / "fpga/icepi-zero/trace.v",
                ROOT / "fpga/icepi-zero/tests/tap_bridge.v",
            ], check=True)
            with subprocess.Popen(
                ["vvp", simulation], stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True
            ) as process:
                try:
                    tap = trace.Tap(SimulatedBridge(process))
                    for trigger in ("now", "reset", "now"):
                        self.assertEqual(tap.identify(), trace.IDCODE)
                        samples = trace.capture(tap, trigger, timeout=3)
                        self.assertEqual(len(samples), 256)
                        start = samples[0] & 0x3fff
                        for index, sample in enumerate(samples):
                            expected = (0x52e << 85 | 0xd7 << 77 | 0xbc << 69 | 0x92 << 61 | 0xc2 << 52 | 0x81 << 44 | 1 << 43 |
                                        0x352 << 31 | 1 << 30 | 0x69 << 22 | 0x53 << 14 |
                                        ((start + index) & 0x3fff))
                            self.assertEqual(sample, expected)

                    path = work / "trace.vcd"
                    trace.write_vcd(path, samples)
                    vcd = path.read_text()
                    self.assertIn("$timescale 1 ns $end", vcd)
                    self.assertIn("$var wire 8 $ register_a $end", vcd)
                    self.assertIn("b01101001 $", vcd)
                    for register, symbol, value in (("b", ",", 0x92), ("c", "-", 0xbc), ("d", ".", 0xd7)):
                        self.assertIn(f"$var wire 8 {symbol} register_{register} $end", vcd)
                        self.assertIn(f"b{value:08b} {symbol}", vcd)
                    self.assertIn("$var wire 11 / sp $end", vcd)
                    self.assertIn("b10100101110 /", vcd)
                    self.assertEqual(len([line for line in vcd.splitlines() if line.startswith("#")]), 257)
                    self.assertTrue(vcd.endswith("#5120\n"))
                finally:
                    process.stdin.close()
                    process.wait(timeout=3)


if __name__ == "__main__":
    unittest.main()
