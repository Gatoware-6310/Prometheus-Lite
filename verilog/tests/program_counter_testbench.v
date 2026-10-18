`timescale 1ns/1ps

module program_counter_testbench;

    reg clk = 0;
    reg reset;
    reg increment;
    reg jump;
    reg [15:0] jump_value;

    wire [15:0] value;

    always #5 clk = ~clk;

    program_counter dut (
        .clk(clk),
        .reset(reset),
        .increment(increment),
        .jump(jump),
        .jump_value(jump_value),
        .value(value)
    );

initial begin
    // Reset test
    reset = 1;
    @(posedge clk);
    #10;
    $display("PC: %d, 0 expected", value);
    reset = 0; // let's not reset on the next iteration

    // Increment test
    increment = 1;
    @(posedge clk);
    #10
    $display("PC: %d, 3 expected", value);

    // Increment again test
    @(posedge clk);
    #10
    $display("PC: %d, 6 expected", value);
    increment = 0;

    // Jump test
    jump = 1;
    jump_value = 100;
    @(posedge clk);
    #10
    $display("PC: %d, 100 expected", value);

    // Overflow test
    jump_value = 65534;
    increment = 1;
    @(posedge clk);
    #10
    jump = 0;
    @(posedge clk);
    #10
    $display("PC: %d, 0 expected", value);

    $finish;
end
endmodule