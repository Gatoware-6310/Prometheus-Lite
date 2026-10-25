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

    wire [10:0] memory_address;
    wire memory_read_enable;
    wire memory_write_enable;
    wire [7:0] memory_write_data;
    wire [7:0] memory_read_data;

    prometheus_lite cpu (
        .clk(clk),
        .reset(~rst_n),
        .memory_address(memory_address),
        .memory_read_enable(memory_read_enable),
        .memory_write_enable(memory_write_enable),
        .memory_write_data(memory_write_data),
        .memory_read_data(memory_read_data)
    );

    `ifdef SYNTHESIS // temporary ram interface; don't try to synthesize 2kb of ram
        reg[7:0] read_data;

        always@(posedge clk) begin
            if(memory_read_enable) read_data <= ui_in; // inject instructions
        end
        
        assign memory_read_data = read_data; // this has to be outside
    `else // use our normal ram interface if we AREN'T synthesizing
        memory ram (
            .clk(clk),
            .address(memory_address),
            .memory_read_enable(memory_read_enable),
            .memory_write_enable(memory_write_enable),
            .write_data(memory_write_data),
            .read_data(memory_read_data)
        );

    `endif

    // This is so that optimization doesn't optimize the whole CPU out
    assign uo_out = memory_address[7:0];
    assign uio_out = memory_write_data;
    assign uio_oe = 8'hFF;
    
    // List all unused inputs to prevent warnings
    wire _unused = &{ena, ui_in, uio_in, 1'b0};

endmodule
