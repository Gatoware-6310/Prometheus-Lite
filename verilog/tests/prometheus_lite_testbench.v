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
    `WAIT
    reset = 0;
    $display("--------- Successful! Probably ---------\n");

    $display("--------- Instruction tests ---------\n");
    // Set the instruction to movi b, 42
    dut.ram.memory[0] = 8'h00;
    dut.ram.memory[1] = 8'h01;
    dut.ram.memory[2] = 8'h3F;
    `WAIT
    if(dut.rf.registers[1] == 63) 
        $display("MOVE IMMEDIATE %d, [PASS]", dut.rf.registers[1]);
    else $fatal(1, "MOVE IMMEDIATE %d, [FAIL]", dut.rf.registers[1]);

    // Set the instruction to movr a, b
    dut.ram.memory[3] = 8'h01;
    dut.ram.memory[4] = 8'h00;
    dut.ram.memory[5] = 8'h01;
    `WAIT
    if(dut.rf.registers[0] == 63)
        $display("MOVE REGISTERS %d, [PASS]", dut.rf.registers[0]);
    else $fatal(1, "MOVE REGISTERS %d, [FAIL]", dut.rf.registers[0]);

    // put a number into the memory address, i think address 0x000
    dut.ram.memory[0] = 255;

    instruction = 24'h020000; // set the instruction to mova 0x000
    `WAIT
    if(dut.rf.registers[0] == 255)
        $display("MOVE MEMORY INTO REGISTER %d, [PASS]", dut.rf.registers[0]);
    else $fatal(1, "MOVE MEMORY INTO REGISTER %d, [FAIL]", dut.rf.registers[0]);
    `WAIT
    $finish;

    $display("");

end

endmodule