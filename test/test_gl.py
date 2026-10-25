
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge, RisingEdge, Timer


@cocotb.test()
async def test_arithmetic(dut):
    dut.ena.value = 1 # Enabled
    # Init all the pins
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0 # Reset

    # Start a 100khz clock
    cocotb.start_soon(Clock(dut.clk, 10, unit="us").start()) #

    # After 10 cycles, release reset
    await ClockCycles(dut.clk, 10)
    await FallingEdge(dut.clk)
    dut.rst_n.value = 1

    async def instruction(opcode, operand1, operand2, cycles):
        # FETCH_A, FETCH_B, FETCH_C, FETCH_C_WAIT, EXECUTE, WRITEBACK, REGISTER_WRITEBACK
        for i, byte in enumerate([opcode, operand1, operand2] + [0] * (cycles - 3)): # Send ONE BYTE per clock cycle
            if i != 0:
                await FallingEdge(dut.clk)
            dut.ui_in.value = byte
            await RisingEdge(dut.clk)
        await FallingEdge(dut.clk)

    await instruction(0x00, 0x00, 63, 6)  # movi a, 63
    await instruction(0x17, 0x00, 8, 6)   # addi a, 8
    await instruction(0x18, 0x00, 10, 6)  # subi a, 10

    # movfa 0, expose the register a
    # Only run 5 cycles so we read while the CPU is in WRITEBACK.
    await instruction(0x06, 0x00, 0x00, 5)

    await Timer(1, unit="ns") # Wait

    result = int(dut.uio_out.value) # Get the result

    dut._log.info(f"Register A: {result} (expected 61)")
    assert result == 61, f"Arithmetic failed: got {result}"

    dut._log.info("GATE LEVEL TEST PASSED!!!!")
