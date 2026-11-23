module top (
    input wire clk,
    input wire [1:0] button,
    input wire usb_rx,
    output wire usb_tx,
    output wire [4:0] led
);

    wire [11:0] memory_address;
    wire memory_read_enable;
    wire memory_write_enable;
    wire [7:0] memory_write_data;
    wire [7:0] memory_read_data;
    wire load, write_byte, reset_project;
    wire [7:0] ui, uo, uio_out, uio_oe;
    wire [7:2] gpio_input;
    wire rst_n = button[0] && !reset_project;
    wire reset = !rst_n || load;
    // trace.ys connects these inputs to existing nets in the flattened CPU.
    wire [11:0] pc, sp;
    wire [2:0] state;
    wire [7:0] opcode, register_a, register_b, register_c, register_d;
    wire zero;

    uart_bridge bridge (
        .clk(clk), .reset(!button[0]), .rx(usb_rx), .tx(usb_tx),
        .ui(ui), .gpio_input(gpio_input), .uo(uo), .uio_out(uio_out), .uio_oe(uio_oe),
        .load(load), .write_byte(write_byte), .reset_project(reset_project)
    );

    tt_um_gatoware_prometheus_lite project (
        .clk(clk), .rst_n(rst_n), .ena(1'b1),
        .ui_in(ui), .uo_out(uo), .uio_in({gpio_input & ~uio_oe[7:2], write_byte, load}),
        .uio_out(uio_out), .uio_oe(uio_oe)
    );

    wire jtck, jtdi, jtdo, jce, jshift, jupdate, jrstn;
    JTAGG #(.ER1("ENABLED"), .ER2("DISABLED")) user_jtag (
        .JTCK(jtck), .JTDI(jtdi), .JTDO1(jtdo), .JTDO2(1'b0),
        .JCE1(jce), .JSHIFT(jshift), .JUPDATE(jupdate), .JRSTN(jrstn)
    );

    icepi_trace trace (
        .clk(clk), .cpu_reset(reset),
        .probes({sp, register_d, register_c, register_b, reset, memory_write_data, memory_read_data, memory_write_enable,
                 memory_read_enable, memory_address, zero, register_a, opcode, state, pc}),
        .jtck(jtck), .jtdi(jtdi), .jtdo(jtdo),
        .jce(jce), .jshift(jshift), .jupdate(jupdate), .jrstn(jrstn)
    );

    assign led = uo[7:3];

endmodule
