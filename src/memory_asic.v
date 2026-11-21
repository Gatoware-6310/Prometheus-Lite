module memory_asic (
    input wire clk,
    input wire memory_read_enable,
    input wire memory_write_enable,
    input wire [11:0] address,
    input wire [7:0] write_data,
    output wire [7:0] read_data,
    input wire fetch,
    output wire [23:0] instruction
);
    wire [9:0] row0, row1, row2;
    wire [2:0] enable, write_bank;
    wire [7:0] q0, q1, q2;

    memory_ports ports (
        .clk(clk), .address(address), .fetch(fetch),
        .read_byte(memory_read_enable), .write_byte(memory_write_enable),
        .row0(row0), .row1(row1), .row2(row2), .enable(enable), .write_bank(write_bank),
        .q0(q0), .q1(q1), .q2(q2), .read_data(read_data), .instruction(instruction)
    );

    gf180mcu_ocd_ip_sram__sram1024x8m8wm1 bank0 (
        .CLK(clk), .CEN(!enable[0]),
        .GWEN(!write_bank[0]), .WEN(8'h00), .A(row0),
        .D(write_data), .Q(q0)
    );

    gf180mcu_ocd_ip_sram__sram1024x8m8wm1 bank1 (
        .CLK(clk), .CEN(!enable[1]),
        .GWEN(!write_bank[1]), .WEN(8'h00), .A(row1),
        .D(write_data), .Q(q1)
    );
    gf180mcu_ocd_ip_sram__sram1024x8m8wm1 bank2 (
        .CLK(clk), .CEN(!enable[2]),
        .GWEN(!write_bank[2]), .WEN(8'h00), .A(row2),
        .D(write_data), .Q(q2)
    );
endmodule
