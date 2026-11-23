module control_unit #(
    parameter[2:0] FETCH = 3'd0,
    parameter[2:0] REGISTER_WRITEBACK = 3'd5,
    parameter[2:0] HALT = 3'd6
) (
    input wire clk,
    input wire enable,
    input wire reset,

    /* Flags */
    output reg zero,

    /* CURRENT INSTRUCTION STUFF, like for jumps */
    output reg jump_pc = 0,
    output reg[11:0] jump_value_pc = 0,

    input wire[7:0] opcode,
    input wire[7:0] operand_1,
    input wire[7:0] operand_2,
    input wire[2:0] state,
    output reg[2:0] next_state,

    /* REGISTER FILE STUFF */
    output reg[1:0] read_register_a,
    output reg[1:0] read_register_b,
    output reg[1:0] read_register_c,
    input wire[7:0] data_a,
    input wire[7:0] data_b,
    input wire[7:0] data_c,
    output reg rf_write_enable,
    output reg[1:0] write_register,
    output reg[7:0] write_data,

    /* STACK STUFF */
    output reg[11:0] stack_pointer,
    
    /* MEMORY STUFF */
    output reg memory_read_enable,
    output reg memory_write_enable,
    output reg[11:0] memory_address,
    output reg[7:0] memory_write_data,
    input wire[7:0] memory_read_data,

    /* I/O STUFF */
    output wire[7:0] io_address,
    input  wire[7:0] io_read_data,
    output wire[7:0] io_write_data,
    output wire io_write_enable
);

    reg zero_next;
    reg write_zero;
    reg [7:0] mul_a, mul_b;

    reg[11:0] sp_next;
    reg write_sp;
    reg stack_fault;

    localparam MOVI = 8'h00;
    localparam MOVR = 8'h01;
    localparam MOVA = 8'h02;
    localparam MOVB = 8'h03;
    localparam MOVC = 8'h04;
    localparam MOVD = 8'h05;
    localparam MOVFA = 8'h06;
    localparam MOVFB = 8'h07;
    localparam MOVFC = 8'h08;
    localparam MOVFD = 8'h09;
    localparam MOVP = 8'h0A;
    localparam MOVFP = 8'h0B;
    localparam ADD = 8'h10;
    localparam SUB = 8'h12;
    localparam ADDI = 8'h17;
    localparam SUBI = 8'h18;
    localparam JMP = 8'h30;
    localparam JZ = 8'h31;
    localparam CMP = 8'h16;
    localparam MUL = 8'h19;
    localparam AND = 8'h20;
    localparam OR = 8'h21;
    localparam XOR = 8'h22;
    localparam NOT = 8'h23;
    localparam SHL = 8'h24;
    localparam SHR = 8'h25;
    localparam JNZ = 8'h32;
    localparam JMPP = 8'h35;
    localparam JZP = 8'h36;
    localparam JNZP = 8'h37;
    localparam PUSH = 8'h40;
    localparam POP = 8'h41;
    localparam IN = 8'h50;
    localparam OUT = 8'h51;
    localparam NOP = 8'h52;
    localparam HLT = 8'h53;

    assign io_address = operand_2; // Constantly set it so that as soon as we get the right opcode it'll work
    assign io_write_data = data_a;
    assign io_write_enable = enable && !reset && opcode == OUT;

    always@(*) begin
        rf_write_enable = 0;
        memory_read_enable = 0;
        memory_write_enable = 0;

        read_register_a = 0;
        read_register_b = 0;
        read_register_c = 0;
        write_register = 0;
        write_data = 0;

        memory_address = 0;
        memory_write_data = 0;

        zero_next = 0;
        write_zero = 0;

        next_state = state;
        jump_pc = 0;
        jump_value_pc = 0;

        sp_next = stack_pointer;
        write_sp = 0;

        case(opcode)
            MOVI: begin // MOVE IMMEDIATE, 0x0, movi [reg], [immediate]
                rf_write_enable = 1;
                write_register = operand_1[1:0]; // move the register number (lowest 2 bits since there's just 4 registers) from the first operand into the register that's gonna be written to 
                write_data = operand_2;
                next_state = REGISTER_WRITEBACK;
            end
            MOVR: begin // move between registers
                rf_write_enable = 1;
                read_register_a = operand_2[1:0];
                write_register = operand_1[1:0];
                write_data = data_a;
                next_state = FETCH;
            end
            MOVA: begin // MOVE BYTE FROM MEMORY INTO A REGISTER, mova [address]
                memory_read_enable = 1;
                memory_address = {operand_1[3:0], operand_2};
                write_register = 0; // set it to a
                rf_write_enable = 1;
                write_data = memory_read_data;
                next_state = REGISTER_WRITEBACK;
            end
            MOVB: begin // MOVE BYTE FROM MEMORY INTO A REGISTER, movb [address]
                memory_read_enable = 1;
                memory_address = {operand_1[3:0], operand_2};
                write_register = 1; // b
                rf_write_enable = 1;
                write_data = memory_read_data;
                next_state = REGISTER_WRITEBACK;
            end
            MOVC: begin // MOVE BYTE FROM MEMORY INTO A REGISTER, movc [address]
                memory_read_enable = 1;
                memory_address = {operand_1[3:0], operand_2};
                write_register = 2; // c
                rf_write_enable = 1;
                write_data = memory_read_data;
                next_state = REGISTER_WRITEBACK;
            end
            MOVD: begin // MOVE BYTE FROM MEMORY INTO A REGISTER, movd [address]
                memory_read_enable = 1;
                memory_address = {operand_1[3:0], operand_2};
                write_register = 3; // d
                rf_write_enable = 1;
                write_data = memory_read_data;
                next_state = REGISTER_WRITEBACK;
            end
            MOVFA: begin
                memory_write_enable = 1;
                read_register_a = 0;
                memory_address = {operand_1[3:0], operand_2};
                memory_write_data = data_a;
                // next state is already 5, writeback. this is what we need because we're writing to memory and we set it up here!
            end
            MOVFB: begin
                memory_write_enable = 1;
                read_register_a = 1;
                memory_address = {operand_1[3:0], operand_2};
                memory_write_data = data_a;
            end
            MOVFC: begin
                memory_write_enable = 1;
                read_register_a = 2;
                memory_address = {operand_1[3:0], operand_2};
                memory_write_data = data_a;
            end
            MOVFD: begin
                memory_write_enable = 1;
                read_register_a = 3;
                memory_address = {operand_1[3:0], operand_2};
                memory_write_data = data_a;
            end
            MOVP: begin
                if(operand_2 == 0) begin
                    read_register_a = 8'h00;
                    read_register_b = 8'h01;
                end else begin
                    read_register_a = 8'h02;
                    read_register_b = 8'h03;
                end
                    memory_read_enable = 1;
                    memory_address = {data_a[3:0], data_b}; // concatenate the last 4 bits of register 2 onto register 1
                    write_register = operand_1[1:0]; // get destination register
                    rf_write_enable = 1;
                    write_data = memory_read_data;
                    next_state = REGISTER_WRITEBACK;
                end
            MOVFP: begin
                if(operand_1 == 0) begin
                    read_register_a = 8'h00;
                    read_register_b = 8'h01;
                end else begin
                    read_register_a = 8'h02;
                    read_register_b = 8'h03;
                end
                memory_address = {data_a[3:0], data_b}; // concatenate the last 4 bits of register 2 onto register 1
                read_register_c = operand_2[1:0];
                memory_write_data = data_c;
                memory_write_enable = 1;
            end
            ADD: begin
                read_register_a = operand_1[1:0]; // destination
                read_register_b = operand_2[1:0]; //source
                write_data = data_a + data_b;

                zero_next = (write_data == 0);
                write_zero = 1;

                write_register = operand_1[1:0];
                rf_write_enable = 1;
                next_state = REGISTER_WRITEBACK;
            end
            SUB: begin
                read_register_a = operand_1[1:0]; // destination
                read_register_b = operand_2[1:0]; //source
                write_data = data_a - data_b;
                
                zero_next = (write_data == 0);
                write_zero = 1;

                write_register = operand_1[1:0];
                rf_write_enable = 1;
                next_state = REGISTER_WRITEBACK;
            end
            ADDI: begin
                read_register_a = operand_1[1:0]; // destination
                write_data = data_a + operand_2; // imediate

                zero_next = (write_data == 0);
                write_zero = 1;

                write_register = operand_1[1:0];
                rf_write_enable = 1;
                next_state = REGISTER_WRITEBACK;
            end
            SUBI: begin
                read_register_a = operand_1[1:0]; // destination
                write_data = data_a - operand_2; // immediate

                zero_next = (write_data == 0);
                write_zero = 1;

                write_register = operand_1[1:0];
                rf_write_enable = 1;
                next_state = REGISTER_WRITEBACK;
            end
            JMP: begin
                jump_pc = 1;
                jump_value_pc = {operand_1[3:0], operand_2};
                next_state = REGISTER_WRITEBACK;
            end
            JZ: begin
                if(zero) begin
                    jump_pc = 1;
                    jump_value_pc = {operand_1[3:0], operand_2};
                end
                next_state = REGISTER_WRITEBACK;
            end
            JNZ: begin
                if(!zero) begin // this should be it?
                    jump_pc = 1;
                    jump_value_pc = {operand_1[3:0], operand_2};
                end
                next_state = REGISTER_WRITEBACK;
            end
            CMP: begin
                read_register_a = operand_1[1:0]; // num1
                read_register_b = operand_2[1:0]; // num2
                
                zero_next = (data_a - data_b == 0);
                write_zero = 1;

                next_state = REGISTER_WRITEBACK;
            end
            MUL: begin
                read_register_a = operand_1[1:0]; // destination
                read_register_b = operand_2[1:0]; //source
                write_data = mul_a * mul_b;

                zero_next = (write_data == 0);
                write_zero = 1;

                write_register = operand_1[1:0];
                rf_write_enable = 1;
                next_state = REGISTER_WRITEBACK;
            end
            AND: begin
                read_register_a = operand_1[1:0]; // destination
                read_register_b = operand_2[1:0]; //source
                write_data = data_a & data_b;

                zero_next = (write_data == 0);
                write_zero = 1;

                write_register = operand_1[1:0];
                rf_write_enable = 1;
                next_state = REGISTER_WRITEBACK;
            end
            OR: begin
                read_register_a = operand_1[1:0]; // destination
                read_register_b = operand_2[1:0]; //source
                write_data = data_a | data_b;

                zero_next = (write_data == 0);
                write_zero = 1;

                write_register = operand_1[1:0];
                rf_write_enable = 1;
                next_state = REGISTER_WRITEBACK;
            end
            XOR: begin
                read_register_a = operand_1[1:0]; // destination
                read_register_b = operand_2[1:0]; //source
                write_data = data_a ^ data_b;

                zero_next = (write_data == 0);
                write_zero = 1;

                write_register = operand_1[1:0];
                rf_write_enable = 1;
                next_state = REGISTER_WRITEBACK;
            end
            NOT: begin
                read_register_a = operand_1[1:0]; // source/destination
                write_data = ~data_a; // one operand only

                zero_next = (write_data == 0); // apparently x86 doesn't update the zero flag on NOT but let's be different
                write_zero = 1;

                write_register = operand_1[1:0];
                rf_write_enable = 1;
                next_state = REGISTER_WRITEBACK;
            end
            SHL: begin
                read_register_a = operand_1[1:0]; // source/destination
                write_data = data_a << 1; // only shift by 1. i should consider changing the isa to allow for shifts by an immediate

                zero_next = (write_data == 0);
                write_zero = 1;

                write_register = operand_1[1:0];
                rf_write_enable = 1;
                next_state = REGISTER_WRITEBACK;
            end
            SHR: begin
                read_register_a = operand_1[1:0]; // source/destination
                write_data = data_a >> 1; // only shift by 1. i should consider changing the isa to allow for shifts by an immediate

                zero_next = (write_data == 0);
                write_zero = 1;

                write_register = operand_1[1:0];
                rf_write_enable = 1;
                next_state = REGISTER_WRITEBACK;
            end
            JMPP: begin
                if(operand_1 == 0) begin
                    read_register_a = 8'h00;
                    read_register_b = 8'h01;
                end else begin
                    read_register_a = 8'h02;
                    read_register_b = 8'h03;
                end
                
                jump_pc = 1;
                jump_value_pc = {data_a[3:0], data_b};
                next_state = REGISTER_WRITEBACK;
            end
            PUSH: begin
                read_register_a = operand_1[1:0];
                if (stack_pointer != 12'h000) begin
                    memory_write_enable = 1;
                    memory_address = stack_pointer;
                    memory_write_data = data_a;
                    sp_next = stack_pointer - 12'd1;
                    write_sp = 1;
                end
            end
            POP: begin
                if (stack_pointer != 12'hBFF) begin
                    // PUSH stores before decrementing SP; POP must read SP + 1.
                    sp_next = stack_pointer + 12'd1;
                    write_sp = 1;
                    rf_write_enable = 1;
                    memory_address = stack_pointer + 12'd1;
                    memory_read_enable = 1;
                    write_register = operand_1[1:0];
                    write_data = memory_read_data;
                end
            end
            NOP: begin
                next_state = REGISTER_WRITEBACK; // just skip to incrementing the pc
            end
            HLT: begin
                next_state = HALT; // stay here forever!
            end
            JZP: begin
                if(zero) begin
                    if(operand_1 == 0) begin
                        read_register_a = 8'h00;
                        read_register_b = 8'h01;
                    end else begin
                        read_register_a = 8'h02;
                        read_register_b = 8'h03;
                    end
                    
                    jump_pc = 1;
                    jump_value_pc = {data_a[3:0], data_b};
                end
                next_state = REGISTER_WRITEBACK;
            end
            JNZP: begin
                if(!zero) begin
                    if(operand_1 == 0) begin
                        read_register_a = 8'h00;
                        read_register_b = 8'h01;
                    end else begin
                        read_register_a = 8'h02;
                        read_register_b = 8'h03;
                    end
                    
                    jump_pc = 1;
                    jump_value_pc = {data_a[3:0], data_b};
                end
                next_state = REGISTER_WRITEBACK;
            end

            IN: begin
                rf_write_enable = 1;
                write_register = operand_1[1:0];
                write_data = io_read_data;
                next_state = REGISTER_WRITEBACK;
            end
            OUT: begin
                read_register_a = operand_1[1:0];
                next_state = REGISTER_WRITEBACK;
            end


            default: begin
                // illegal instruction! maybe an exception register later?
            end
        endcase
    end

    // for flags/sp to write at the same time
    always @(posedge clk) begin
        if (reset) begin
            stack_pointer <= 12'hBFF;
            zero <= 0;
            stack_fault <= 1'b0;
        end else begin
            if (enable && ((opcode == PUSH && stack_pointer == 12'h000) ||
                           (opcode == POP && stack_pointer == 12'hBFF)))
                stack_fault <= 1'b1;
            if (enable && opcode == MUL) begin
                mul_a <= data_a;
                mul_b <= data_b;
            end
            if (write_zero && (opcode == MUL ? state == REGISTER_WRITEBACK : enable))
                zero <= zero_next;
            if (write_sp && (opcode == POP ? state == REGISTER_WRITEBACK : enable))
                stack_pointer <= sp_next;
        end
    end

endmodule