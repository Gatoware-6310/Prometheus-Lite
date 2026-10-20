/* Previously register.v, no longer unused! */

module program_counter(
    input wire clk,
    input wire reset,
    input wire increment,
    input wire jump,
    input wire[10:0] jump_value,
    output reg[10:0] value
);

always @(posedge clk) begin
        if(reset) begin // reset takes priority
            value <= 0;
        end else if(jump) begin // jumps take second priority
            value <= jump_value;
        end else if (increment) begin // incrementing is last
        if(value < 65533) begin
            value <= value + 3;
        end else value <= 0;
    end
end

endmodule