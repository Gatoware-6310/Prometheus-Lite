
`timescale 1ns/1ps
`define WAIT \
    repeat(7) @(negedge clk); // we wait for the falling edge 7 TIMES because the cpu does its work on the rising edge, and it has to do 7 cyces of work.

module run_program;

reg clk = 0;
reg reset = 0;
reg [7:0] program_bytes [0:3071];

always #5 clk = ~clk;

wire [11:0] memory_address;
wire memory_read_enable;
wire memory_write_enable;
wire [7:0] memory_write_data;
wire [7:0] memory_read_data;
wire memory_fetch;
wire [23:0] memory_instruction;

prometheus_lite dut(
    .clk(clk),
    .reset(reset),
    .memory_address(memory_address),
    .memory_read_enable(memory_read_enable),
    .memory_write_enable(memory_write_enable),
    .memory_write_data(memory_write_data),
    .memory_read_data(memory_read_data),
    .memory_fetch(memory_fetch),
    .memory_instruction(memory_instruction),
    .io_read_data(8'h00)
);

memory ram(
    .clk(clk),
    .address(memory_address),
    .memory_read_enable(memory_read_enable),
    .memory_write_enable(memory_write_enable),
    .write_data(memory_write_data),
    .read_data(memory_read_data),
    .fetch(memory_fetch),
    .instruction(memory_instruction)
);

initial begin
    $display("--------- Resetting the CPU ---------\n");
    // Reset the cpu first
    reset = 1;

    `WAIT
    $display("--------- Successful! Probably ---------\n");

    $display("--------- Program Start ---------\n");

    $readmemh("build/programs/program.bin.hex", program_bytes);
    for (integer i = 0; i < 3072; i = i + 1)
        ram.load_byte(i, program_bytes[i]); // Assuming you're running the makefile from the root, I mean how else would you right?

    reset = 0;
    wait(0); // magic
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
