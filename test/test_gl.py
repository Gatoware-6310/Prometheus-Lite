import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge, Timer


async def load_program(dut, program, ui=0, gpio=0):
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

    dut.ui_in.value = ui
    dut.uio_in.value = gpio & 0xfc


@cocotb.test()
async def test_arithmetic(dut):
    program = [
        0x00, 0, 63,  # movi a, 63
        0x17, 0, 8,   # addi a, 8
        0x18, 0, 10,  # subi a, 10
        0x51, 0, 1,   # out a, 0x01
        0x53, 0, 0,   # hlt
    ]
    await load_program(dut, program)
    for cycle in range(1, 41):
        await FallingEdge(dut.clk)
        await Timer(1, unit="ns")
        value = dut.uo_out.value
        if value.is_resolvable and int(value) == 61:
            assert cycle == 15, f"Expected output in cycle 15, got {cycle}"
            return

    assert False, "CPU did not output the arithmetic result"


@cocotb.test()
async def test_program_across_sram_banks(dut):
    program = bytearray(0x7FA)
    program[:3] = bytes([0x30, 0x07, 0xFA])  # jmp 0x7fa
    program.extend([
        0x00, 0x00, 19,    # movi a, 19
        0x06, 0x0B, 0xFF,  # movfa 0xbff
        0x00, 0x00, 0,     # clear A (first instruction in bank 2)
        0x02, 0x0B, 0xFF,  # mova 0xbff
        0x51, 0x00, 0x01,  # out a, 0x01
        0x17, 0x00, 23,    # addi a, 23
        0x06, 0x07, 0xF0,  # movfa 0x7f0
        0x00, 0x00, 0,     # clear A before attempting the readback
        0x02, 0x07, 0xF0,  # mova 0x7f0
        0x51, 0x00, 0x01,  # out a, 0x01
        0x06, 0x00, 0xA5,  # movfa 0x0a5
        0x00, 0x00, 0,
        0x02, 0x00, 0xA5,  # mova 0x0a5
        0x17, 0x00, 1,
        0x51, 0x00, 0x01,  # out a, 0x01
        0x53, 0x00, 0x00,  # hlt
    ])
    await load_program(dut, program)

    for expected in (19, 42, 43):
        for _ in range(100):
            await FallingEdge(dut.clk)
            value = dut.uo_out.value
            if value.is_resolvable and int(value) == expected:
                break
        else:
            assert False, f"Missing CPU memory result: {expected}"


@cocotb.test()
async def test_jump_to_modified_code(dut):
    program = [
        0x00, 0, 0x00,
        0x06, 0, 0x10,
        0x00, 0, 77,
        0x06, 0, 0x12,
        0x30, 0, 0x10,
        0,
        0x53, 0, 0,
        0x51, 0, 0x01,
        0x53, 0, 0,
    ]
    await load_program(dut, program)

    for _ in range(35):
        await FallingEdge(dut.clk)
        value = dut.uo_out.value
        if value.is_resolvable and int(value) == 77:
            return
    assert False, "CPU did not execute the modified instruction"


@cocotb.test()
async def test_multiply_zero_branch_and_stack(dut):
    program = [
        0x00, 0x00, 16,
        0x00, 0x01, 16,
        0x19, 0x00, 0x01,
        0x31, 0x00, 0x12,
        0x53, 0x00, 0x00,
        0x53, 0x00, 0x00,
        0x00, 0x00, 0xA7,
        0x40, 0x00, 0x00,
        0x00, 0x00, 0x00,
        0x41, 0x00, 0x00,
        0x51, 0x00, 0x01,
        0x53, 0x00, 0x00,
    ]
    await load_program(dut, program)

    for _ in range(60):
        await FallingEdge(dut.clk)
        value = dut.uo_out.value
        if value.is_resolvable and int(value) == 0xA7:
            return
    assert False, "Multiply, conditional jump, or stack readback failed"


@cocotb.test()
async def test_gpio(dut):
    program = [
        0x50, 0, 0x00,  # in a, 0x00
        0x51, 0, 0x01,  # out a, 0x01
        0x50, 1, 0x12,  # read ui[2]
        0x51, 1, 0x01,
        0x51, 1, 0x27,  # set uo[7]
        0x00, 2, 0x54,
        0x51, 2, 0x02,  # set GPIO latch
        0x00, 2, 0x50,
        0x51, 2, 0x03,  # enable GPIO[4] and GPIO[6]
        0x50, 3, 0x02,
        0x51, 3, 0x01,
        0x50, 3, 0x35,  # read GPIO[5] from outside
        0x51, 3, 0x01,
        0x00, 2, 0,
        0x51, 2, 0x34,  # clear GPIO[4]
        0x50, 3, 0x02,
        0x51, 3, 0x01,
        0x50, 3, 0x03,
        0x51, 3, 0x01,
        0x51, 1, 0x30,  # reserved loader pin
        0x51, 1, 0xff,  # unmapped address
        0x50, 3, 0xff,
        0x51, 3, 0x01,
        0x53, 0, 0,
    ]
    await load_program(dut, program, ui=0xa5, gpio=0xa4)

    last_cycle = 0
    for cycle, expected in [
        (7, 0xa5), (15, 1), (19, 0x81), (43, 0xf4),
        (51, 1), (67, 0xe4), (75, 0x50), (91, 0),
    ]:
        for _ in range(cycle - last_cycle):
            await FallingEdge(dut.clk)
        assert int(dut.uo_out.value) == expected
        last_cycle = cycle

    assert int(dut.uio_oe.value) == 0x50
    assert int(dut.uio_out.value) == 0x44

    dut.rst_n.value = 0
    await FallingEdge(dut.clk)
    assert int(dut.uio_oe.value) == 0
    assert int(dut.uio_out.value) == 0
