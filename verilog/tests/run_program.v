
`timescale 1ns/1ps
`define WAIT \
    repeat(7) @(negedge clk); // we wait for the falling edge 7 TIMES because the cpu does its work on the rising edge, and it has to do 7 cyces of work.

module run_program;

reg clk = 0;
reg reset = 0;

always #5 clk = ~clk;

prometheus_lite dut(
    .clk(clk),
    .reset(reset)
);

initial begin
    $display("--------- Resetting the CPU ---------\n");
    // Reset the cpu first
    reset = 1;

    `WAIT
    $display("--------- Successful! Probably ---------\n");

    $display("--------- Program Start ---------\n");

    $readmemh("build/programs/program.bin.hex", dut.ram.memory); // Assuming you're running the makefile from the root, I mean how else would you right?

    reset = 0;
    wait(0);
end

initial begin
    #1000000;
    $display("Program timed out!");
    $display("REGISTERS:");
    $display("A: %d, B: %d, C: %d, D: %d, PC: %d", dut.rf.registers[0], dut.rf.registers[1], dut.rf.registers[2], dut.rf.registers[3], dut.value_pc);
    $display("FLAGS:");
    $display("Zero: ", dut.zero);
    $finish;
end

endmodule
