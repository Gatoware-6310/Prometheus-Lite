module control_unit (
    input wire clk,
    /* CURRENT INSTRUCTION STUFF */
    input wire[7:0] opcode,
    input wire[7:0] operand_1,
    input wire[7:0] operand_2,

    /* REGISTER FILE STUFF */
    output reg rf_write_enable,
    output reg[1:0] write_register,
    output reg[7:0] write_data
);

    always@(posedge clk) begin
        rf_write_enable <= 0;
        case(opcode) 
            8'h0: begin// MOVE IMMEDIATE, 0x0
                rf_write_enable <= 1;
                write_register <= operand_1[1:0]; // move the register number (lowest 2 bits since there's just 4 registers) from the first operand into the register that's gonna be written to 
                write_data <= operand_2;
            end
        endcase
    end

endmodule