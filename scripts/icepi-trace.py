#!/usr/bin/env python3
"""Capture Prometheus-Lite samples over the Icepi Zero FT231X USB JTAG port."""
import argparse
import ctypes as C
from ctypes.util import find_library
from pathlib import Path
import sys
import time

IDCODE = 0x41111043
ER1 = 0x32
DEPTH = 256
SCAN_BITS = 120
SIGNATURE = 0xA9
SIGNATURE_SHIFT = 112
ADDRESS_SHIFT = 104
VALID, ARM, RESET_TRIGGER = 1 << 10, 1 << 8, 1 << 9
DONE, ACK = 1 << 103, 1 << 102
SAMPLE_MASK = (1 << 99) - 1
FIELDS = (
    ("pc", 12), ("state", 3), ("opcode", 8), ("register_a", 8),
    ("zero", 1), ("memory_address", 12), ("memory_read_enable", 1),
    ("memory_write_enable", 1), ("memory_read_data", 8),
    ("memory_write_data", 8), ("reset", 1),
    ("register_b", 8), ("register_c", 8), ("register_d", 8), ("sp", 12),
)
# FT231X modem pins as wired on Icepi Zero (openFPGALoader board definition).
TMS, TCK, TDI, TDO = 0x40, 0x20, 0x80, 0x08


class Ftdi:
    def __init__(self, serial):
        library = find_library("ftdi1")
        if not library:
            raise RuntimeError("Install libftdi (Arch package: libftdi)")
        self.lib = C.CDLL(library)
        ptr, integer, string = C.c_void_p, C.c_int, C.c_char_p
        for name, args, result in (
            ("new", [], ptr), ("free", [ptr], None),
            ("usb_open_desc", [ptr, integer, integer, string, string], integer),
            ("usb_close", [ptr], integer),
            ("set_baudrate", [ptr, integer], integer),
            ("set_latency_timer", [ptr, C.c_ubyte], integer),
            ("set_bitmode", [ptr, C.c_ubyte, C.c_ubyte], integer),
            ("tcioflush", [ptr], integer),
            ("write_data", [ptr, ptr, integer], integer),
            ("read_data", [ptr, ptr, integer], integer),
            ("get_error_string", [ptr], string),
        ):
            fn = getattr(self.lib, "ftdi_" + name)
            fn.argtypes, fn.restype = args, result
        self.serial = serial
        self.ctx = None

    def call(self, name, *args):
        result = getattr(self.lib, "ftdi_" + name)(self.ctx, *args)
        if result < 0:
            message = self.lib.ftdi_get_error_string(self.ctx).decode()
            raise RuntimeError(f"FT231X {name}: {message}")
        return result

    def __enter__(self):
        self.ctx = self.lib.ftdi_new()
        if not self.ctx:
            raise RuntimeError("Could not allocate libftdi context")
        self.opened = False
        try:
            self.call("usb_open_desc", 0x0403, 0x6015, None,
                      self.serial.encode() if self.serial else None)
            self.opened = True
            self.call("set_latency_timer", 2)
            self.call("set_baudrate", 100_000)
            self.call("set_bitmode", TMS | TCK | TDI, 4)  # synchronous bit-bang
            self.call("tcioflush")
        except BaseException:
            self.__exit__(None, None, None)
            raise
        return self

    def __exit__(self, *_):
        if self.opened:
            self.lib.ftdi_set_bitmode(self.ctx, 0, 0)
            self.lib.ftdi_usb_close(self.ctx)
        self.lib.ftdi_free(self.ctx)

    def shift(self, cycles):
        pins = bytearray()
        for tms, tdi in cycles:
            low = (TMS if tms else 0) | (TDI if tdi else 0)
            pins.extend((low, low | TCK))
        # Bound each write/read pair below the FT231X receive FIFO size.
        for start in range(0, len(pins), 256):
            chunk = pins[start:start + 256]
            tx = (C.c_ubyte * len(chunk)).from_buffer(chunk)
            if self.call("write_data", tx, len(chunk)) != len(chunk):
                raise RuntimeError("Short FT231X write")
            rx = (C.c_ubyte * len(chunk))()
            count = 0
            deadline = time.monotonic() + 1
            while count < len(chunk):
                count += self.call("read_data", C.byref(rx, count), len(chunk) - count)
                if count < len(chunk) and time.monotonic() >= deadline:
                    raise RuntimeError("Timed out reading FT231X GPIO samples")
            # Synchronous bit-bang samples before applying each output byte.
            yield from (bool(rx[i] & TDO) for i in range(1, len(chunk), 2))


class Tap:
    def __init__(self, bridge):
        self.bridge = bridge

    def reset(self):
        list(self.bridge.shift([(1, 0)] * 6 + [(0, 0)]))

    def scan(self, width, value=0, instruction=False):
        # Run-Test/Idle -> Select-DR -> [Select-IR ->] Capture -> Shift.
        prefix = [(1, 0)] * (2 if instruction else 1) + [(0, 0)] * 2
        data = [(bit == width - 1, (value >> bit) & 1) for bit in range(width)]
        # Exit1 -> Update -> Idle, with extra clocks for the JTAGG read port.
        response = list(self.bridge.shift(prefix + data + [(1, 0)] + [(0, 0)] * 5))
        return sum(bit << index for index, bit in enumerate(response[len(prefix):len(prefix) + width]))

    def identify(self):
        self.reset()
        code = self.scan(32)
        if code != IDCODE:
            raise RuntimeError(f"Expected ECP5 IDCODE 0x{IDCODE:08x}, got 0x{code:08x}")
        return code

    def trace(self, request=0):
        response = self.scan(SCAN_BITS, request)
        if response >> SIGNATURE_SHIFT != SIGNATURE:
            raise RuntimeError(f"ER1 signature missing (received 0x{response:030x}). "
                               "The host script requires the matching analyzer bitstream.")
        return response


def capture(tap, trigger, timeout):
    ir = tap.scan(8, ER1, instruction=True)
    if ir & 3 != 1:
        raise RuntimeError(f"Unexpected JTAG Capture-IR pattern: 0x{ir:02x}")
    target_ack = (tap.trace() & ACK) ^ ACK
    tap.trace(VALID | ARM | (RESET_TRIGGER if trigger == "reset" else 0))
    if trigger == "reset":
        print("Press and release the Icepi Zero CPU reset button (button[0]).", flush=True)
    deadline = time.monotonic() + timeout
    # Status scan requests address zero so the next scan can return sample zero.
    response = tap.trace(VALID)
    while (response & ACK) != target_ack or not response & DONE:
        if time.monotonic() >= deadline:
            raise RuntimeError("Capture timed out waiting for the trigger or arm acknowledgement. "
                               "If a previous reset capture is armed, press and release reset.")
        time.sleep(0.01)
        response = tap.trace(VALID)
    samples = []
    for address in range(DEPTH):
        request = VALID | (address + 1) if address < DEPTH - 1 else 0
        response = tap.trace(request)
        if (response >> ADDRESS_SHIFT) & 0xff != address or (response & (DONE | ACK)) != (DONE | target_ack):
            raise RuntimeError(f"Unexpected capture status or address at sample {address}")
        samples.append(response & SAMPLE_MASK)
    return samples


def write_vcd(path, samples):
    with path.open("w", encoding="ascii") as output:
        print("$timescale 1 ns $end\n$scope module cpu $end", file=output)
        offset = 0
        signals = []
        for index, (name, width) in enumerate(FIELDS):
            symbol = chr(33 + index)
            print(f"$var wire {width} {symbol} {name} $end", file=output)
            signals.append((symbol, offset, width))
            offset += width
        print("$upscope $end\n$enddefinitions $end", file=output)
        for cycle, sample in enumerate(samples):
            print(f"#{20 * cycle}", file=output)
            for symbol, offset, width in signals:
                value = (sample >> offset) & ((1 << width) - 1)
                print(f"{value}{symbol}" if width == 1 else f"b{value:0{width}b} {symbol}",
                      file=output)
        print(f"#{20 * len(samples)}", file=output)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--detect", action="store_true", help="read the physical JTAG IDCODE only")
    parser.add_argument("--serial", help="select an FT231X by USB serial number")
    parser.add_argument("--trigger", choices=("reset", "now"), default="reset")
    parser.add_argument("--timeout", type=float, default=30, help="trigger timeout in seconds")
    parser.add_argument("--output", type=Path, default=Path("build/icepi/trace.vcd"))
    args = parser.parse_args()
    if not args.timeout > 0:
        parser.error("--timeout must be positive")
    try:
        with Ftdi(args.serial) as bridge:
            tap = Tap(bridge)
            print(f"ECP5 JTAG IDCODE 0x{tap.identify():08x}")
            if args.detect:
                return 0
            samples = capture(tap, args.trigger, args.timeout)
        args.output.parent.mkdir(parents=True, exist_ok=True)
        write_vcd(args.output, samples)
        print(f"Wrote {len(samples)} samples to {args.output}")
    except (OSError, RuntimeError) as error:
        print(error, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
