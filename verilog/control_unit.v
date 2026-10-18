module control_unit;

wire[7:0] opcode;
wire[7:0] operand_1;
wire[7:0] operand_2;

always@(posedge clk) begin
    case(opcode) 
        0:
        
        default:
    endcase

end

endmodule