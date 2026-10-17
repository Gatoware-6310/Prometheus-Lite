`timescale 1ns/1ps

module register_testbench;
    reg clk = 0;
    reg reset = 0;
    reg enable = 0;

    reg[7:0] proposed_value;
    reg[7:0] value;

    always #5 clk = ~clk;

    register dut (
        .clk(clk),
        .reset(reset),
        .proposed_value(proposed_value),
        .enable(enable),
        .value(value)
    );


initial begin
    // Reset test, tests if resetting works
    reset = 1;
    enable = 0;
    proposed_value = 100;

    @(posedge clk);
    #1;
    $display("RESET: %d, expecting 0", value);

    // Write test, tests if writing works
    @(negedge clk); // Negedge waits for the falling edge, posedge is the opposite.
    reset = 0;
    enable = 1;
    proposed_value = 42;

    @(posedge clk);
    #1;
    $display("WRITE: %d, expecting 42", value);

    // Tests if it'll hold the value
    @(negedge clk);
    enable = 0;
    proposed_value = 99;

    @(posedge clk);
    #1;
    $display("HOLD: %d, expecting 42", value);

    // Priority test, tests if resettining takes priority
    @(negedge clk);
    reset = 1;
    enable = 1;
    proposed_value = 200;

    @(posedge clk);
    #1;
    $display("RESET PRIORITY: %d, expecting 0", value);

    $finish;
end
endmodule