/* TOP LEVEL */
module prometheus_lite(
    input wire clk,
    input wire reset,

    output wire [10:0] memory_address,
    output wire memory_read_enable,
    output wire memory_write_enable,
    output wire [7:0] memory_write_data,
    input wire [7:0] memory_read_data
);
    /* Flags */
    wire zero;

    /* IR stuff */
    wire[7:0] opcode;
    wire[7:0] operand_1;
    wire[7:0] operand_2;
    reg[23:0] instruction;

    /* Control Unit stuff/Register File stuff */
    wire rf_write_enable;
    wire[1:0] read_register_a;
    wire[1:0] read_register_b;
    wire[1:0] read_register_c;
    wire[1:0] write_register;
    wire[7:0] write_data;
    wire[7:0] alu_opcode;
    // Register file outputs
    wire[7:0] data_a;
    wire[7:0] data_b;
    wire[7:0] data_c;

    /* Stack Pointer */
    reg[10:0] stack_pointer;

    /* Fetch signals */
    reg [10:0] fetch_address;
    reg fetch_read_enable;

    /* Control unit signals */
    wire [10:0] cu_memory_address;
    wire cu_memory_read_enable;
    wire cu_memory_write_enable;
    wire [7:0] cu_memory_write_data;

    /* Program Counter stuff */
    wire jump_pc;
    wire[10:0] jump_value_pc;
    wire[10:0] value_pc;

    // State can be 6 things, so ceil(log2(6)) = 3
    // i swear discovered that formula myself btw anyone else reading this be proud of me (even though it's very obvious)
    reg[2:0] state;
    reg[2:0] next_state;

    localparam FETCH_A = 0;
    localparam FETCH_B = 1;
    localparam FETCH_C = 2;
    localparam FETCH_C_WAIT = 3;
    localparam EXECUTE = 4;
    localparam WRITEBACK = 5;
    localparam REGISTER_WRITEBACK = 6;
    localparam HALT = 7;

    wire fetching = (state <= FETCH_C_WAIT);

    assign memory_address =
        fetching ? ((state == FETCH_A) ? value_pc : fetch_address)
                : cu_memory_address; // first multiplexer! if we're fetching, then if it's the first state (fetch_A), the address should be the vaule of the program counter, or if it's not the first state it should be the value of the fetch address. if we're NOT fetching, set it to the value that the control unit wants it to be


    assign memory_read_enable =
        fetching ? fetch_read_enable : cu_memory_read_enable; // if we're fetching, fetch if read enable is true, otherwise follow the cu

    assign memory_write_enable =
        !fetching && (state == EXECUTE || (state == WRITEBACK && opcode != 8'h40)) && cu_memory_write_enable; // only enable writes if we're not fetching, the state is writeback, and the cu wants to write. also fix a stack bug

    assign memory_write_data = cu_memory_write_data; // just make it what the cu wants
    
    instruction_register ir(
        .clk(clk),
        .reset(reset),
        .enable(state == FETCH_C_WAIT),
        .instruction({instruction[23:8], memory_read_data}),
        .opcode(opcode),
        .operand_1(operand_1),
        .operand_2(operand_2)
    );

    control_unit cu(
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
        .increment(state == REGISTER_WRITEBACK && opcode != 8'h30 && !(opcode == 8'h31 && zero)), // increment on register writeback aswell but be careful of jumps/jz
        .jump(jump_pc),
        .jump_value(jump_value_pc),
        .value(value_pc)
    );

    /* STATE MACHINE: Changes the current state *on every rising clock edge thingy!!!!* */
    always @(posedge clk) begin
        if (reset) begin
            state <= FETCH_A;
            fetch_address <= 0;
            fetch_read_enable <= 1;
        end else begin
            case(state)
                FETCH_A: begin
                        fetch_address <= value_pc + 1;
                        fetch_read_enable <= 1;
                        state <= FETCH_B; 
                    end
                FETCH_B: begin
                        instruction[23:16] <= memory_read_data;
                        fetch_address <= value_pc + 2;
                        state <= FETCH_C;
                    end
                FETCH_C: begin
                        instruction[15:8] <= memory_read_data;
                        state <= FETCH_C_WAIT;
                    end
                FETCH_C_WAIT: begin
                        instruction[7:0] <= memory_read_data;
                        state <= EXECUTE;
                    end
                EXECUTE:
                    if (next_state == FETCH_A)
                        state <= REGISTER_WRITEBACK;
                    else if (next_state != state)
                        state <= next_state;
                    else
                        state <= WRITEBACK;
                WRITEBACK:
                    state <= REGISTER_WRITEBACK;
                REGISTER_WRITEBACK:
                    state <= FETCH_A;
                HALT: // this should never reach execution
                    state <= HALT; // just loop infinitely, very simple. 
                default:
                    // illegal state?? how did you even get here
                    state <= FETCH_A;
            endcase
        end
    end

endmodule
