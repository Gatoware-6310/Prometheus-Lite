/* Adapting program_counter.v */

module instruction_register(
    input wire clk,
    input wire reset,
    input wire[23:0] instruction,
    output reg[7:0] opcode,
    output reg[7:0] operand_1,
    output reg[7:0] operand_2
);

always @(posedge clk) begin
    if(reset) begin // reset takes priority
        opcode <= 0;
        operand_1 <= 0;
        operand_2 <= 0;
    end else begin 
        opcode <= instruction[23:16]; // set the opcode to the first byte
        operand_1 <= instruction[15:8]; // first operand to the second
        operand_2 <= instruction[7:0]; // second operand to the third
        // the last bit in the last byte from left to right is technically the first/0
    end
end

endmodule