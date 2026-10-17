module register_file ( // Set up stuff
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

/* combinational reads i think */
assign data_a = registers[read_register_a];
assign data_b = registers[read_register_b];


/* this happens on the high clock edge, resets all the registers if the input for that is true */
always@(posedge clk) begin
    if(reset) begin // reset takes priority
        for (integer i = 0; i < 8; i = i + 1) begin
            registers[i] <= 0;
        end
    end else if(enable) begin // if we don't want to reset and we're writing, write.
        registers[write_register] <= write_data;
    end
end


endmodule