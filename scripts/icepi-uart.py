#!/usr/bin/env python3
import argparse
import os
from pathlib import Path
import select
import termios
import tty


def exchange(port, command, response_size=0):
    os.write(port, command)
    response = bytearray()
    while len(response) < response_size + 1:
        if not select.select([port], [], [], 2)[0]:
            raise ValueError(f"no reply to command {command[:1]!r}")
        data = os.read(port, response_size + 1 - len(response))
        if not data:
            raise ValueError("serial port disconnected")
        response.extend(data)
        if response[0] != 0x06:
            raise ValueError(f"bridge rejected command {command[:1]!r}: 0x{response[0]:02x}")
    return response[1:]


def main():
    parser = argparse.ArgumentParser(description="Use the Prometheus Lite pin interface over Icepi Zero USB UART")
    parser.add_argument("port", help="serial device, e.g. /dev/ttyUSB0")
    commands = parser.add_subparsers(dest="command", required=True)
    load = commands.add_parser("load", help="load a raw binary and start the CPU")
    load.add_argument("program", type=Path)
    commands.add_parser("reset", help="pulse the project reset")
    commands.add_parser("status", help="read the output pins")
    inputs = commands.add_parser("input", help="set the runtime input byte")
    inputs.add_argument("value", type=lambda value: int(value, 0), choices=range(256), metavar="BYTE")
    gpio_input = commands.add_parser("gpio-input", help="set the external levels for uio[7:2]")
    gpio_input.add_argument("value", type=lambda value: int(value, 0), choices=range(256), metavar="BYTE")
    commands.add_parser("pins", help="read the output pins and direction mask")
    args = parser.parse_args()

    try:
        if args.command == "load":
            program = args.program.read_bytes()
            if not 1 <= len(program) <= 3072:
                raise ValueError("program must contain 1 to 3072 bytes")
        port = os.open(args.port, os.O_RDWR | os.O_NOCTTY)
        try:
            tty.setraw(port)
            settings = termios.tcgetattr(port)
            settings[2] &= ~termios.CRTSCTS
            settings[2] |= termios.CLOCAL | termios.CREAD
            settings[4] = settings[5] = termios.B115200
            termios.tcsetattr(port, termios.TCSAFLUSH, settings)

            if args.command == "load":
                exchange(port, b"L")
                for byte in program:
                    exchange(port, bytes((ord("W"), byte)))
                exchange(port, b"R")
                print(f"Loaded {len(program)} bytes and started the CPU.")
            elif args.command == "reset":
                exchange(port, b"X")
            elif args.command == "input":
                exchange(port, bytes((ord("I"), args.value)))
            elif args.command == "gpio-input":
                exchange(port, bytes((ord("G"), args.value)))
            elif args.command == "pins":
                uo, uio, oe = exchange(port, b"P", 3)
                print(f"uo=0x{uo:02x} uio_out=0x{uio:02x} uio_oe=0x{oe:02x}")
            else:
                uo, uio = exchange(port, b"S", 2)
                print(f"uo=0x{uo:02x} uio_out=0x{uio:02x}")
        finally:
            os.close(port)
    except (OSError, ValueError) as error:
        parser.exit(1, f"{error}\n")


if __name__ == "__main__":
    main()
