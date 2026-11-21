module memory_asic (
    input wire clk,
    input wire memory_read_enable,
    input wire memory_write_enable,
    input wire [11:0] address,
    input wire [7:0] write_data,
    output wire [7:0] read_data
);
    wire [7:0] bank0_data, bank1_data, bank2_data;
    wire write_byte = memory_write_enable && !memory_read_enable;
    wire access_byte = memory_read_enable || write_byte;
    reg [1:0] read_bank;

    always @(posedge clk)
        if (memory_read_enable)
            read_bank <= address[11:10];

    assign read_data = read_bank == 2'd0 ? bank0_data :
                       read_bank == 2'd1 ? bank1_data :
                       read_bank == 2'd2 ? bank2_data : 8'h00;

    gf180mcu_ocd_ip_sram__sram1024x8m8wm1 bank0 (
        .CLK(clk), .CEN(!(access_byte && address[11:10] == 2'd0)),
        .GWEN(!write_byte), .WEN(8'h00), .A(address[9:0]),
        .D(write_data), .Q(bank0_data)
    );

    gf180mcu_ocd_ip_sram__sram1024x8m8wm1 bank1 (
        .CLK(clk), .CEN(!(access_byte && address[11:10] == 2'd1)),
        .GWEN(!write_byte), .WEN(8'h00), .A(address[9:0]),
        .D(write_data), .Q(bank1_data)
    );
    gf180mcu_ocd_ip_sram__sram1024x8m8wm1 bank2 (
        .CLK(clk), .CEN(!(access_byte && address[11:10] == 2'd2)),
        .GWEN(!write_byte), .WEN(8'h00), .A(address[9:0]),
        .D(write_data), .Q(bank2_data)
    );
endmodule
