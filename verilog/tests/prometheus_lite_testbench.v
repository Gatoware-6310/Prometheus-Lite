`define WAIT \ 
    repeat(2) @(negedge clk); // we wait for the falling edge TWICE because the cpu does its work on the rising edge, and it has to FETCH and EXECUTE, taking 2 cycles.

module prometheus_lite_testbench;

reg clk = 0;
reg reset = 0;
reg ir_enable = 0;
reg[23:0] instruction;

always #5 clk = ~clk;

prometheus_lite dut(
    .clk(clk),
    .reset(reset),
    .instruction(instruction)
);

initial begin
    // Reset the cpu first
    reset = 1;
    `WAIT
    reset = 0;

    // Set the instruction to movi b, 42
    instruction = 24'h00013F;
    `WAIT
    if(dut.rf.registers[1] == 63) 
        $display("MOVE IMMEDIATE %d, [PASS]", dut.rf.registers[1]);
    else $fatal(1, "MOVE IMMEDIATE %d, [FAIL]", dut.rf.registers[1]);

    // Set the instruction to movr a, b
    instruction = 24'h010001;
    `WAIT
    if(dut.rf.registers[0] == 63)
        $display("MOVE REGISTERS %d, [PASS]", dut.rf.registers[0]);
    else $fatal(1, "MOVE REGISTERS %d, [FAIL]", dut.rf.registers[0]);
    $finish;

end

endmodule