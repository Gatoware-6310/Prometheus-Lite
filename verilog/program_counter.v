/* Previously register.v, no longer unused! */

module register(
    input wire clk,
    input wire reset,
    input wire increment, // D
    output reg[15:0] value // Q
);

always @(posedge clk) begin
    if(reset) begin
        value <= 0;
    end else if (increment) begin
        value <= value + 3;
    end
end

endmodule