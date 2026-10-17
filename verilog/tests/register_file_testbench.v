`timescale 1ns/1ps

module register_file_testbench;

    reg clk = 0;
    reg enable = 0;
    reg reset;

    reg [2:0] read_register_a;
    reg [2:0] read_register_b;
    reg [2:0] write_register;

    reg [7:0] write_data;

    wire [7:0] data_a;
    wire [7:0] data_b; 

    always #5 clk = ~clk;

    register_file dut (
        .clk(clk),
        .read_register_a(read_register_a),
        .read_register_b(read_register_b),
        .write_register(write_register),
        .write_data(write_data),
        .enable(enable),
        .data_a(data_a),
        .data_b(data_b),
        .reset(reset)
    );


initial begin
    // Reset test, tests if all registers reset
    reset = 1;
    enable = 0;
    write_register = 0;
    write_data = 100;
    read_register_a = 0;
    read_register_b = 7;

    @(posedge clk);
    #1;
    $display("RESET: A is %d, B is %d, expecting 0, 0", data_a, data_b);

    // Write test, tests if writing works
    @(negedge clk);
    reset = 0;
    enable = 1;
    write_register = 3;
    write_data = 42;
    read_register_a = 3;
    read_register_b = 3;

    @(posedge clk);
    #1;
    $display("WRITE: A is %d, B is %d, expecting 42, 42", data_a, data_b);

    // Tests if they'll hold the value
    @(negedge clk);
    enable = 0;
    write_data = 99;

    @(posedge clk);
    #1;
    $display("HOLD: A is %d, B is %d, expecting 42, 42", data_a, data_b);

    // Dual read test, tests reading two different registers at the same time
    @(negedge clk);
    enable = 1;
    write_register = 5;
    write_data = 99;

    @(posedge clk);
    #1;
    read_register_a = 3;
    read_register_b = 5;
    #1;
    $display("DUAL READ: A is %d, B is %d, expecting 42, 99", data_a, data_b);

    // Reset priority test, tests if resetting takes priority
    @(negedge clk);
    reset = 1;
    enable = 1;
    write_register = 3;
    write_data = 200;

    @(posedge clk);
    #1;
    $display("RESET PRIORITY: A is %d, B is %d, expecting 0, 0", data_a, data_b);

    $finish;
end
endmodule