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

    /* Memory stuff */
    wire memory_read_enable;
    wire memory_write_enable;
    wire[10:0] memory_address;
    wire[7:0] memory_write_data;
    wire[7:0] memory_read_data;

    // State can be 5 things, so ceil(log2(5)) = 3
    // i swear discovered that formula myself btw anyone else reading this be proud of me (even though it's very obvious)
    reg[2:0] state;
    reg[2:0] next_state;

    localparam FETCH_A = 0;
    localparam FETCH_B = 1;
    localparam FETCH_C = 2;
    localparam EXECUTE = 3;
    localparam WRITEBACK = 4;
    localparam REGISTER_WRITEBACK = 5;


    memory ram(
      .clk(clk),
      .memory_read_enable(memory_read_enable),
      .memory_write_enable(memory_write_enable && state == WRITEBACK), // && writeback just to be safe
      .address(memory_address),
      .write_data(memory_write_data),
      .read_data(memory_read_data)  
    );

    instruction_register ir(
        .clk(clk),
        .reset(reset),
        .enable(state == FETCH_A || state == FETCH_B || state == FETCH_C),
        .instruction(instruction),
        .opcode(opcode),
        .operand_1(operand_1),
        .operand_2(operand_2)
    );

    control_unit cu(
        .clk(clk),
        .enable(state == EXECUTE),
        .opcode(opcode),
        .operand_1(operand_1),
        .operand_2(operand_2),
        .write_register(write_register),
        .write_data(write_data),
        .rf_write_enable(rf_write_enable),
        .read_register_a(read_register_a),
        .read_register_b(read_register_b),
        .data_a(data_a),
        .data_b(data_b),
        .memory_read_enable(memory_read_enable),
        .memory_write_enable(memory_write_enable),
        .memory_address(memory_address),
        .memory_write_data(memory_write_data),
        .memory_read_data(memory_read_data),
        .state(state),
        .next_state(next_state)
    );

    register_file rf(
        .clk(clk),
        .reset(reset),
        .enable(rf_write_enable && state == EXECUTE || rf_write_enable && state == REGISTER_WRITEBACK),
        .read_register_a(read_register_a),
        .read_register_b(read_register_b),
        .write_register(write_register),
        .write_data(write_data),
        .data_a(data_a),
        .data_b(data_b)
    );

    /* STATE MACHINE: Changes the current state *on every rising clock edge thingy!!!!* */
    always @(posedge clk) begin
        if (reset) begin
            state <= FETCH_A;
        end else begin
            case(state)
                FETCH_A:
                    // TODO: Fetch from the program counter
                    state <= FETCH_B;
                FETCH_B:
                    // TODO: ditto
                    state <= FETCH_C;
                FETCH_C:
                    // TODO: shiny ditto
                    state <= EXECUTE;
                EXECUTE:
                    if (next_state != state)
                        state <= next_state;
                    else
                        state <= WRITEBACK;
                WRITEBACK:
                    state <= REGISTER_WRITEBACK;
                REGISTER_WRITEBACK:
                    state <= FETCH_A;
                default:
                    // illegal state?? how did you even get here
                    state <= FETCH_A;
            endcase
        end
    end

endmodule