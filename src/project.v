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
    wire memory_fetch;
    wire [23:0] memory_instruction;

    wire [7:0] io_address, io_write_data;
    wire io_write_enable;
    reg [7:0] io_read_data;
    reg [7:0] output_latch;
    reg [7:2] gpio_latch, gpio_direction;

    wire load_program = uio_in[0];
    reg [11:0] load_address;
    reg load_strobe_previous;
    wire load_write = load_program && uio_in[1] && !load_strobe_previous && (load_address < 12'hC00);

    always @(posedge clk) begin
        if (!rst_n || !load_program) begin
            load_address <= 0;
            load_strobe_previous <= 1'b0;
        end else begin
            load_strobe_previous <= uio_in[1];
            if (load_write)
                load_address <= load_address + 1'b1;
        end
    end

    prometheus_lite cpu (
        .clk(clk),
        .reset(!rst_n || load_program),
        .memory_address(memory_address),
        .memory_read_enable(memory_read_enable),
        .memory_write_enable(memory_write_enable),
        .memory_write_data(memory_write_data),
        .memory_read_data(memory_read_data),
        .memory_fetch(memory_fetch),
        .memory_instruction(memory_instruction),
        .io_address(io_address),
        .io_read_data(io_read_data),
        .io_write_data(io_write_data),
        .io_write_enable(io_write_enable)
    );

    wire read_byte = rst_n && !load_program && memory_read_enable;
    wire write_byte = rst_n && (load_program ? load_write : memory_write_enable);

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
        .read_data(memory_read_data),
        .fetch(rst_n && !load_program && memory_fetch),
        .instruction(memory_instruction)
    );

    wire [7:0] gpio_value = {
        (uio_in[7:2] & ~gpio_direction) | (gpio_latch & gpio_direction),
        2'b00
    };

    assign uo_out = output_latch;
    assign uio_out = {gpio_latch, 2'b00};
    assign uio_oe = (rst_n && !load_program) ? {gpio_direction, 2'b00} : 8'b0;

    always @* begin
        case (io_address)
            8'h00: io_read_data = ui_in;
            8'h01: io_read_data = output_latch;
            8'h02: io_read_data = gpio_value;
            8'h03: io_read_data = {gpio_direction, 2'b00};
            default: begin
                case (io_address[7:3])
                    5'h02: io_read_data = {7'b0, ui_in[io_address[2:0]]};
                    5'h04: io_read_data = {7'b0, output_latch[io_address[2:0]]};
                    5'h06: io_read_data = {7'b0, gpio_value[io_address[2:0]]};
                    default: io_read_data = 8'h00;
                endcase
            end
        endcase
    end

    always @(posedge clk) begin
        if (!rst_n || load_program) begin
            output_latch <= 0;
            gpio_latch <= 0;
            gpio_direction <= 0;
        end else if (io_write_enable) begin
            case (io_address)
                8'h01: output_latch <= io_write_data;
                8'h02: gpio_latch <= io_write_data[7:2];
                8'h03: gpio_direction <= io_write_data[7:2];
                default: begin
                    if (io_address[7:3] == 5'h04)
                        output_latch[io_address[2:0]] <= io_write_data[0];
                    if (io_address >= 8'h32 && io_address <= 8'h37)
                        gpio_latch[io_address[2:0]] <= io_write_data[0];
                end
            endcase
        end
    end

    wire _unused = &{ena, 1'b0};
endmodule
