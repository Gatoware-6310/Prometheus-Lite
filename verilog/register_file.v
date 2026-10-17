module register_file (
    input wire clk,
    input wire enable,
    input wire reset,

    input wire[2:0] read_register_a,
    input wire[2:0] read_register_b,
    input wire[2:0] write_register,

    input wire[7:0] write_data,

    output wire[7:0] data_a,
    output wire[7:0] data_b
);

reg [7:0] registers [0:7]; // an array of 8 8 bit `reg`s

// combinational
assign data_a = registers[read_register_a];
assign data_b = registers[read_register_b];


// on the clock edge thingy
always@(posedge clk) begin
    if(reset) begin
        for (integer i = 0; i < 8; i = i + 1) begin
            registers[i] <= 0;
        end
    end else if(enable) begin
        registers[write_register] <= write_data;
    end
end


endmodule