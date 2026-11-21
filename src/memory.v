/* Portable RAM for simulation and FPGA builds */

module memory(
    input wire clk,
    input wire memory_read_enable,
    input wire memory_write_enable,
    input wire[11:0] address,
    input wire[7:0] write_data,
    output reg[7:0] read_data
);

(* ram_style = "distributed" *) reg[7:0] memory[0:3071];


`ifdef ICEPI_ZERO
initial begin
    $readmemh("fpga/icepi-zero/program.hex", memory);
end
`endif

always@(posedge clk) begin
    if(memory_read_enable) begin // reads will take priority. if read enable AND write enable are both `1`, it'll read
        read_data <= address < 12'hc00 ? memory[address] : 8'h00;
    end else if(memory_write_enable && address < 12'hc00) begin
        memory[address] <= write_data;
    end
end

endmodule