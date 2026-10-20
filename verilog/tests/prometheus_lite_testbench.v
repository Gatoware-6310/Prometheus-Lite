
`timescale 1ns/1ps
`define WAIT \
    repeat(7) @(negedge clk); // we wait for the falling edge 7 TIMES because the cpu does its work on the rising edge, and it has to do 7 cyces of work.
module prometheus_lite_testbench;

reg clk = 0;
reg reset = 0;
reg ir_enable = 0;
reg[23:0] instruction;

always #5 clk = ~clk;

prometheus_lite dut(
    .clk(clk),
    .reset(reset)
);

/*
always @(posedge clk) begin // FOR HEAVIER DEBUGGING
    if (!reset)
        $display("State: %d, Next State: %d, Current: %0xh",
                 $time, dut.state, dut.next_state, dut.opcode);
end
*/

initial begin
    $display("--------- Resetting the CPU ---------\n");
    // Reset the cpu first
    reset = 1;

    // Set the instruction to movi b, 63
    dut.ram.memory[0] = 8'h00;
    dut.ram.memory[1] = 8'h01;
    dut.ram.memory[2] = 8'h3F;

    // Set the instruction to movr c, b
    dut.ram.memory[3] = 8'h01;
    dut.ram.memory[4] = 8'h02;
    dut.ram.memory[5] = 8'h01;

    // Set the instruction to mova 0x100
    dut.ram.memory[6] = 8'h02;
    dut.ram.memory[7] = 8'h01;
    dut.ram.memory[8] = 8'h00;

    // Set the instruction to movfa 0x200
    dut.ram.memory[9] = 8'h06;
    dut.ram.memory[10] = 8'h02;
    dut.ram.memory[11] = 8'h00;

    // put a number into the memory address, 0x100
    dut.ram.memory[256] = 255;

    `WAIT
    reset = 0;
    $display("--------- Successful! Probably ---------\n");

    $display("--------- Instruction tests ---------\n");

    wait(dut.value_pc == 3); // wait until we're done executing that instruction
    @(negedge clk); // wait until the work is done for sure
    if(dut.rf.registers[1] == 63)
        $display("MOVE IMMEDIATE %d, [PASS]", dut.rf.registers[1]);
    else $fatal(1, "MOVE IMMEDIATE %d, [FAIL]", dut.rf.registers[1]);

    wait(dut.value_pc == 6);
    @(negedge clk);
    if(dut.rf.registers[2] == 63)
        $display("MOVE REGISTERS %d, [PASS]", dut.rf.registers[2]);
    else $fatal(1, "MOVE REGISTERS %d, [FAIL]", dut.rf.registers[2]);

    wait(dut.value_pc == 9);
    @(negedge clk);
    if(dut.rf.registers[0] == 255)
        $display("MOVE MEMORY INTO REGISTER %d, [PASS]", dut.rf.registers[0]);
    else $fatal(1, "MOVE MEMORY INTO REGISTER %d, [FAIL]", dut.rf.registers[0]);

    wait(dut.value_pc == 12);
    @(negedge clk)
    if(dut.ram.memory[512] == 255)
        $display("MOVE BYTE FROM REGISTER INTO MEMORY %d, [PASS]", dut.ram.memory[512]);
    else
        $fatal(1, "MOVE BYTE FROM REGISTER INTO MEMORY %d, [FAIL]", dut.ram.memory[512]);




    $display("");
    $finish;

end

initial begin
    #10000;
    $fatal(1, "TEST TIMEOUT");
end

endmodule
