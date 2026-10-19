module prometheus_lite_testbench;

reg clk = 0;
reg reset = 0;
reg ir_enable = 0;
reg[23:0] instruction;

always #5 clk = ~clk;

prometheus_lite dut(
    .clk(clk),
    .reset(reset),
    .ir_enable(ir_enable),
    .instruction(instruction)
);

initial begin
    // Reset the cpu first
    reset = 1;
    @(negedge clk);
    reset = 0;

    // Set the instruction to movi b, 42
    instruction = 24'h00013F;
    ir_enable = 1;
    repeat(2)@(negedge clk);
    ir_enable = 0;

    $display("MOVE IMMEDIATE (movi b, 63): %d, 63 expected", dut.rf.registers[1]);

    // Set the instruction to movr a, b
    instruction = 24'h010001;
    ir_enable = 1;
    repeat(2)@(negedge clk);
    ir_enable = 0;

    $display("MOVE BETWEEN REGISTERS (movr a, b): %d, 63 expected", dut.rf.registers[0]);
    $finish;

end

endmodule