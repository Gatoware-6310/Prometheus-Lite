/* Memory frontend/interface, we don't actually need to put 2kb of memory worth of transistors on the chip */

module memory(
    input wire clk,
    input wire memory_read_enable,
    input wire memory_write_enable,
    input wire[10:0] address,
    input wire[7:0] write_data,
    output reg[7:0] read_data
);

reg[7:0] memory[0:2047];

always@(posedge clk) begin
    if(memory_read_enable) begin // reads will take priority. if read enable AND write enable are both `1`, it'll read
        read_data <= memory[address];
    end else if(memory_write_enable) begin
        memory[address] <= write_data;
    end
end

endmodule