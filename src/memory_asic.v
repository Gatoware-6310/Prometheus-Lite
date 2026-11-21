module memory_asic (
    input wire clk,
    input wire memory_read_enable,
    input wire memory_write_enable,
    input wire [10:0] address,
    input wire [7:0] write_data,
    output wire [7:0] read_data
);
    wire [7:0] bank0_data, bank1_data;
    wire write_byte = memory_write_enable && !memory_read_enable;
    wire access_byte = memory_read_enable || write_byte;
    reg read_bank;

    always @(posedge clk)
        if (memory_read_enable)
            read_bank <= address[10];

    assign read_data = read_bank ? bank1_data : bank0_data;

    gf180mcu_ocd_ip_sram__sram1024x8m8wm1 bank0 (
        .CLK(clk), .CEN(!(access_byte && !address[10])),
        .GWEN(!write_byte), .WEN(8'h00), .A(address[9:0]),
        .D(write_data), .Q(bank0_data)
    );

    gf180mcu_ocd_ip_sram__sram1024x8m8wm1 bank1 (
        .CLK(clk), .CEN(!(access_byte && address[10])),
        .GWEN(!write_byte), .WEN(8'h00), .A(address[9:0]),
        .D(write_data), .Q(bank1_data)
    );
endmodule
