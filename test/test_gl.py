import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge, Timer


async def load_program(dut, program):
    dut.ena.value = 1
    dut.rst_n.value = 0
    dut.ui_in.value = 0
    dut.uio_in.value = 1
    cocotb.start_soon(Clock(dut.clk, 10, unit="us").start())

    await ClockCycles(dut.clk, 2)
    await FallingEdge(dut.clk)
    dut.rst_n.value = 1
    dut.uio_in.value = 3
    for byte in program:
        dut.ui_in.value = byte
        await FallingEdge(dut.clk)

    dut.uio_in.value = 0


@cocotb.test()
async def test_arithmetic(dut):
    program = [
        0x00, 0, 63,  # movi a, 63
        0x17, 0, 8,   # addi a, 8
        0x18, 0, 10,  # subi a, 10
        0x06, 0, 0,   # movfa 0
        0x53, 0, 0,   # hlt
    ]
    await load_program(dut, program)
    for _ in range(40):
        await FallingEdge(dut.clk)
        await Timer(1, unit="ns")
        value = dut.uio_out.value
        if value.is_resolvable and int(value) == 61:
            return

    assert False, "CPU did not write the arithmetic result after loading SRAM"


@cocotb.test()
async def test_program_across_sram_banks(dut):
    program = bytearray(0x7FA)
    program[:3] = bytes([0x30, 0x07, 0xFA])  # jmp 0x7fa
    program.extend([
        0x00, 0x00, 19,    # movi a, 19
        0x06, 0x0B, 0xFF,  # movfa 0xbff
        0x00, 0x00, 0,     # clear A (first instruction in bank 2)
        0x02, 0x0B, 0xFF,  # mova 0xbff
        0x17, 0x00, 23,    # addi a, 23
        0x06, 0x07, 0xF0,  # movfa 0x7f0
        0x00, 0x00, 0,     # clear A before attempting the readback
        0x02, 0x07, 0xF0,  # mova 0x7f0
        0x06, 0x00, 0xA5,  # movfa 0x0a5
        0x53, 0x00, 0x00,  # hlt
    ])
    await load_program(dut, program)

    expected = [(0xFF, 19), (0xF0, 42), (0xA5, 42)]
    for _ in range(100):
        await FallingEdge(dut.clk)
        address, data = dut.uo_out.value, dut.uio_out.value
        if address.is_resolvable and data.is_resolvable:
            if (int(address), int(data)) == expected[0]:
                expected.pop(0)
                if not expected:
                    return
    assert not expected, f"Missing CPU memory results: {expected}"
