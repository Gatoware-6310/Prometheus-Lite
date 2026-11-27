/* TOP LEVEL */
module prometheus_lite(
    input wire clk,
    input wire reset,

    output wire [11:0] memory_address,
    output wire memory_read_enable,
    output wire memory_write_enable,
    output wire [7:0] memory_write_data,
    input wire [7:0] memory_read_data,
    output wire memory_fetch,
    input wire [23:0] memory_instruction,
    output wire [7:0] io_address,
    input  wire [7:0] io_read_data,
    output wire [7:0] io_write_data,
    output wire       io_write_enable
);
    /* Flags */
    wire zero;

    /* IR stuff */
    wire[7:0] opcode;
    wire[7:0] operand_1;
    wire[7:0] operand_2;
    reg jumped;

    /* Control Unit stuff/Register File stuff */
    wire rf_write_enable;
    wire[1:0] read_register_a;
    wire[1:0] read_register_b;
    wire[1:0] read_register_c;
    wire[1:0] write_register;
    wire[7:0] write_data;
    // Register file outputs
    wire[7:0] data_a;
    wire[7:0] data_b;
    wire[7:0] data_c;

    /* Stack Pointer */
    reg[11:0] stack_pointer;

    /* Control unit signals */
    wire [11:0] cu_memory_address;
    wire cu_memory_read_enable;
    wire cu_memory_write_enable;
    wire [7:0] cu_memory_write_data;

    /* Program Counter stuff */
    wire jump_pc;
    wire[11:0] jump_value_pc;
    wire[11:0] value_pc;

    reg [2:0] state;
    wire [2:0] next_state;

    localparam [2:0] FETCH = 3'd0;
    localparam [2:0] DECODE = 3'd1;
    localparam [2:0] EXECUTE = 3'd2;
    localparam [2:0] MEMORY = 3'd3;
    // localparam [2:0] WRITEBACK = 3'd4; redundant!
    localparam [2:0] REGISTER_WRITEBACK = 3'd4;
    localparam [2:0] HALT = 3'd5;

    reg [11:0] data_address;
    reg [7:0] data_write;
    reg data_read, data_store;

    wire fetching = state == FETCH;
    wire accessing = state == MEMORY && !reset;
    assign memory_fetch = fetching && !reset;
    assign memory_address = fetching ? value_pc : data_address;
    assign memory_read_enable = accessing && data_read;
    assign memory_write_enable = accessing && data_store;
    assign memory_write_data = state == MEMORY ? data_write : 8'h00;

    instruction_register ir(
        .clk(clk),
        .reset(reset),
        .enable(state == DECODE),
        .instruction(memory_instruction),
        .opcode(opcode),
        .operand_1(operand_1),
        .operand_2(operand_2)
    );

    control_unit #(
        .FETCH(FETCH),
        .REGISTER_WRITEBACK(REGISTER_WRITEBACK),
        .HALT(HALT)
    ) cu(
        .reset(reset),
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
        .read_register_c(read_register_c),
        .data_a(data_a),
        .data_b(data_b),
        .data_c(data_c),
        .memory_read_enable(cu_memory_read_enable),
        .memory_write_enable(cu_memory_write_enable),
        .memory_address(cu_memory_address),
        .memory_write_data(cu_memory_write_data),
        .memory_read_data(memory_read_data),
        .io_address(io_address),
        .io_read_data(io_read_data),
        .io_write_data(io_write_data),
        .io_write_enable(io_write_enable),
        .state(state),
        .next_state(next_state),
        .zero(zero),
        .jump_pc(jump_pc),
        .jump_value_pc(jump_value_pc),
        .stack_pointer(stack_pointer)
    );

    register_file rf(
        .clk(clk),
        .reset(reset),
        .enable(rf_write_enable && state == REGISTER_WRITEBACK),
        .read_register_a(read_register_a),
        .read_register_b(read_register_b),
        .read_register_c(read_register_c),
        .write_register(write_register),
        .write_data(write_data),
        .data_a(data_a),
        .data_b(data_b),
        .data_c(data_c)
    );

    program_counter pc(
        .clk(clk),
        .reset(reset),
        .increment(state == REGISTER_WRITEBACK && !jumped),
        .jump(state == EXECUTE && jump_pc),
        .jump_value(jump_value_pc),
        .value(value_pc)
    );

    always @(posedge clk) begin
        if (reset) begin
            state <= FETCH;
            jumped <= 0;
            data_address <= 0;
            data_write <= 0;
            data_read <= 0;
            data_store <= 0;
        end else begin
            if (state == EXECUTE) begin
                jumped <= jump_pc;
                data_address <= cu_memory_address;
                data_write <= cu_memory_write_data;
                data_read <= cu_memory_read_enable;
                data_store <= cu_memory_write_enable;
            end
            case (state)
                FETCH: state <= DECODE;
                DECODE: state <= EXECUTE;
                EXECUTE:
                    if (cu_memory_read_enable || cu_memory_write_enable)
                        state <= MEMORY;
                    else if (next_state == FETCH)
                        state <= REGISTER_WRITEBACK;
                    else if (next_state != state)
                        state <= next_state;
                    else
                        state <= REGISTER_WRITEBACK;

                MEMORY: state <= REGISTER_WRITEBACK;
                REGISTER_WRITEBACK: state <= FETCH;
                HALT: state <= HALT;
                default: state <= FETCH;
            endcase
        end
    end
endmodule
