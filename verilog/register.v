/* Unused for now */

module register(
    input wire clk,
    input wire reset,
    input wire enable,
    input wire[7:0] proposed_value, // D
    output reg[7:0] value // Q
);

always @(posedge clk) begin
    if (reset) begin
        value <= 0;
    end else if (enable) begin
        value <= proposed_value;
    end
end

endmodule