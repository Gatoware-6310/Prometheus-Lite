module control_unit;

    /* CURRENT INSTRUCTION STUFF */
    wire[7:0] opcode;
    wire[7:0] operand_1;
    wire[7:0] operand_2;

    /* REGISTER FILE STUFF */
    wire[1:0] read_register_a;
    wire[1:0] read_register_b;
    wire[1:0] write_register;

    wire[7:0] write_data;

    wire[7:0] data_a;
    wire[7:0] data_b;


    always@(posedge clk) begin
        case(opcode) 
            8'h0: // MOVE IMMEDIATE, 0x0
                write_register <= operand_1[1:0]; // move the register number (lowest 2 bits since there's just 4 registers) from the first operand into the register that's gonna be written to 
                write_data <= operand_2;
            default:
        endcase

    end

endmodule