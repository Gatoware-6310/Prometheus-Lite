module control_unit (
    input wire clk,
    /* CURRENT INSTRUCTION STUFF */
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
    output reg[7:0] write_data
);

    always@(*) begin
        rf_write_enable = 0;
        case(opcode) 
            8'h0: begin// MOVE IMMEDIATE, 0x0
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
        endcase
    end

endmodule