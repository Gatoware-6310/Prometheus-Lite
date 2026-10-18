module instruction_register_testbench;

    reg clk = 0;
    reg reset;
    reg enable;
    reg[23:0] instruction;
    wire[7:0] opcode;
    wire[7:0] operand_1;
    wire[7:0] operand_2;

    always #5 clk = ~clk;
    
    instruction_register dut (
        .clk(clk),
        .reset(reset),
        .instruction(instruction),
        .opcode(opcode),
        .enable(enable),
        .operand_1(operand_1),
        .operand_2(operand_2)
    );

    initial begin
        // Reset test
        reset = 1;
        @(posedge clk);
        #10
        $display("OPCODE: %d, 0 expected\nOPERAND 1: %d, 0 expected\nOPERAND 2: %d, 0 expected\n", opcode, operand_1, operand_2);
        reset = 0;

        // Proper instruction test
        enable = 1;
        instruction = 24'h100001; // opcode: 0x10, operand 1: 0x00, operand 2: 0x01
        @(posedge clk)
        #10
        $display("OPCODE: 0x%h, 0x10 expected\nOPERAND 1: 0x%h, 0x00 expected\nOPERAND 2: 0x%h, 0x01 expected\n", opcode, operand_1, operand_2);
        enable = 0;

        // hold test
        instruction = 24'h001100; // testing if when it's not enabled it'll capture/read a new value
        @(posedge clk)
        #20
        $display("OPCODE: 0x%h, 0x10 expected\nOPERAND 1: 0x%h, 0x00 expected\nOPERAND 2: 0x%h, 0x01 expected\n", opcode, operand_1, operand_2);

        $finish;
    end

endmodule