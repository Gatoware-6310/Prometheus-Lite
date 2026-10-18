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

    // Set the instruction to movi a, 42
    instruction = 24'h00003F;
    ir_enable = 1;
    repeat(3) @(negedge clk);
    ir_enable = 0;

    $display("%d, 63 expected", dut.rf.registers[0]);
    $finish;

end

endmodule