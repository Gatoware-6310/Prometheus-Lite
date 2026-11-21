import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge, Timer


@cocotb.test()
async def test_arithmetic(dut):
    dut.ena.value = 1
    dut.rst_n.value = 0
    dut.ui_in.value = 0
    dut.uio_in.value = 1
    cocotb.start_soon(Clock(dut.clk, 10, unit="us").start())

    await ClockCycles(dut.clk, 2)
    await FallingEdge(dut.clk)
    dut.rst_n.value = 1
    dut.uio_in.value = 3
    program = [
        0x00, 0, 63,  # movi a, 63
        0x17, 0, 8,   # addi a, 8
        0x18, 0, 10,  # subi a, 10
        0x06, 0, 0,   # movfa 0
        0x53, 0, 0,   # hlt
    ]
    for byte in program:
        dut.ui_in.value = byte
        await FallingEdge(dut.clk)

    dut.uio_in.value = 0
    for _ in range(40):
        await FallingEdge(dut.clk)
        await Timer(1, unit="ns")
        value = dut.uio_out.value
        if value.is_resolvable and int(value) == 61:
            return

    assert False, "CPU did not write the arithmetic result after loading SRAM"
