module control_unit (
    input wire clk,
    /* CURRENT INSTRUCTION STUFF, like for jumps */
    input wire[7:0] opcode,
    input wire[7:0] operand_1,
    input wire[7:0] operand_2,

    /* REGISTER FILE STUFF */
    output reg[1:0] read_register_a,
    output reg[1:0] read_register_b,
    input wire[7:0] data_a,
    input wire[7:0] data_b,
    output reg rf_write_enable,
    output reg[1:0] write_register,
    output reg[7:0] write_data,
    
    /* MEMORY STUFF */
    input wire memory_read_enable,
    input wire memory_write_enable,
    input wire[10:0] memory_address,
    input wire[7:0] memory_write_data,
    output reg[7:0] memory_read_data
);

    always@(*) begin
        rf_write_enable = 0;
        memory_read_enable = 0;
        memory_write_enable = 0;
        write_register = 0;
        memory_address = 0;
        write_data = 0;
        read_register_a = 0;
        case(opcode) 
            8'h0: begin // MOVE IMMEDIATE, 0x0, movi [reg], [immediate]
                rf_write_enable = 1;
                write_register = operand_1[1:0]; // move the register number (lowest 2 bits since there's just 4 registers) from the first operand into the register that's gonna be written to 
                write_data = operand_2;
            end
            8'h01: begin
                rf_write_enable = 1;
                read_register_a = operand_2[1:0];
                write_register = operand_1[1:0];
                write_data = data_a;
            end
            8'h02: begin // MOVE BYTE FROM MEMORY INTO A REGISTER, mova [address]
                rf_write_enable = 1;
                memory_read_enable = 1;
                memory_address = operand_2;
                write_register = 0; // set it to a
                write_data = {operand_1 + operand_2[2:0]}; // concatenate the last 3 bits of operand 2 onto operand 1
            end
            8'h03: begin // MOVE BYTE FROM MEMORY INTO A REGISTER, movb [address]
                rf_write_enable = 1;
                memory_read_enable = 1;
                memory_address = operand_2;
                write_register = 1; // b
                write_data = {operand_1 + operand_2[2:0]};
            end
            8'h04: begin // MOVE BYTE FROM MEMORY INTO A REGISTER, movc [address]
                rf_write_enable = 1;
                memory_read_enable = 1;
                memory_address = operand_2;
                write_register = 2; // c
                write_data = {operand_1 + operand_2[2:0]};
            end
            8'h05: begin // MOVE BYTE FROM MEMORY INTO A REGISTER, movd [address]
                rf_write_enable = 1;
                memory_read_enable = 1;
                memory_address = operand_2;
                write_register = 3; // d
                write_data = {operand_1 + operand_2[2:0]};
            end
            default: begin
                // illegal instruction! maybe an exception register later?
            end
        endcase
    end

endmodule