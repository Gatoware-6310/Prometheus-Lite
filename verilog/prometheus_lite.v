/* TOP LEVEL */
module prometheus_lite(
    input wire clk,
    input wire reset,
    input wire[23:0] instruction
);
    /* IR stuff */

    wire[7:0] opcode;
    wire[7:0] operand_1;
    wire[7:0] operand_2;

    /* Control Unit stuff/Register File stuff */
    wire rf_write_enable;
    wire[1:0] read_register_a;
    wire[1:0] read_register_b;
    wire[1:0] write_register;
    wire[7:0] write_data;
    wire[7:0] alu_opcode;
    // Register file outputs
    wire[7:0] data_a;
    wire[7:0] data_b;

    // State is either FETCH or EXECUTE, 1 bit
    reg state;
    localparam FETCH = 0; // im gonna add this local param stuff to the alu and cu and stuff maybe tomorrow, just learned about it
    localparam EXECUTE = 1;

    instruction_register ir(
        .clk(clk),
        .reset(reset),
        .enable(state == FETCH),
        .instruction(instruction),
        .opcode(opcode),
        .operand_1(operand_1),
        .operand_2(operand_2)
    );

    control_unit cu(
        .clk(clk),
        .opcode(opcode),
        .operand_1(operand_1),
        .operand_2(operand_2),
        .write_register(write_register),
        .write_data(write_data),
        .rf_write_enable(rf_write_enable),
        .read_register_a(read_register_a),
        .read_register_b(read_register_b),
        .data_a(data_a),
        .data_b(data_b)
    );

    register_file rf(
        .clk(clk),
        .reset(reset),
        .enable(rf_write_enable && state == EXECUTE),
        .read_register_a(read_register_a),
        .read_register_b(read_register_b),
        .write_register(write_register),
        .write_data(write_data),
        .data_a(data_a),
        .data_b(data_b)
    );

    always @(posedge clk) begin
        if (reset) begin
            state <= FETCH;
        end else begin
            state = ~state; // i really hate how verilog makes it ~ instead of ! :(
        end
    end

endmodule