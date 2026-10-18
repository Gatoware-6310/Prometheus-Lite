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
    @(posedge clk);
    #10;
    reset = 0;

    // Set the instruction to movi a, 42
    instruction = 24'h00003F;
    ir_enable = 1;
    @(posedge clk);
    #10;
    ir_enable = 0;

    @(posedge clk);
    #30;

    $display("%d", dut.rf.registers[0]);

end

endmodule