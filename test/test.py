# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Timer


@cocotb.test()
async def test_project(dut):
    dut._log.info("Starting Prometheus-Lite")

    # Start the clock
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    # Reset
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0

    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1

    dut._log.info("Running program")

    # Run it for 30 clock cycles
    await ClockCycles(dut.clk, 30)
    await Timer(1, unit="ns")

    # Read the address
    address = int(dut.uo_out.value)

    dut._log.info(f"Current memory address: {address}")

    # We only have 2 instructions that loops back to 0, so we should never be at an address more than 5
    assert address in (0, 1, 2, 3, 4, 5), (
        f"Address was not 0-5.: {address}"
    )

    dut._log.info("Prometheus-Lite test passed!")