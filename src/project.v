/*
 * Copyright (c) 2026 Gatoware
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_gatoware_prometheus_lite (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    wire [11:0] memory_address;
    wire memory_read_enable;
    wire memory_write_enable;
    wire [7:0] memory_write_data;
    wire [7:0] memory_read_data;

    wire load_program = uio_in[0];
    reg [11:0] load_address;

    always @(posedge clk) begin
        if (!rst_n || !load_program)
            load_address <= 0;
        else if (uio_in[1])
            load_address <= load_address + 1'b1;
    end

    prometheus_lite cpu (
        .clk(clk),
        .reset(!rst_n || load_program),
        .memory_address(memory_address),
        .memory_read_enable(memory_read_enable),
        .memory_write_enable(memory_write_enable),
        .memory_write_data(memory_write_data),
        .memory_read_data(memory_read_data)
    );

    wire read_byte = rst_n && !load_program && memory_read_enable;
    wire write_byte = rst_n && (load_program ? uio_in[1] : memory_write_enable);

`ifdef PROMETHEUS_ASIC_SRAM
    memory_asic ram (
`else
    memory ram (
`endif
        .clk(clk),
        .address(load_program ? load_address : memory_address),
        .memory_read_enable(read_byte),
        .memory_write_enable(write_byte),
        .write_data(load_program ? ui_in : memory_write_data),
        .read_data(memory_read_data)
    );

    assign uo_out = memory_address[7:0];
    assign uio_out = memory_write_data;
    assign uio_oe = 8'hfc;

    wire _unused = &{ena, uio_in[7:2], 1'b0};
endmodule
