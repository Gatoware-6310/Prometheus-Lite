/* TOP LEVEL */
module prometheus_lite(
    input wire clk,
    input wire reset
);
    /* IR stuff */
    wire [7:0] opcode;
    wire [7:0] operand_1;
    wire [7:0] operand_2;

    /* Control Unit stuff */
    wire register_write_enable;
    wire [1:0] read_register_a;
    wire [1:0] read_register_b;
    wire [1:0] write_register;
    wire [7:0] alu_opcode;

    // Register file outputs
    wire [7:0] data_a;
    wire [7:0] data_b;

endmodule