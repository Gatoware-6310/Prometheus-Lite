module top (
    input wire clk,
    input wire [1:0] button,
    output wire [4:0] led
);

    wire [10:0] memory_address;
    wire memory_read_enable;
    wire memory_write_enable;
    wire [7:0] memory_write_data;
    wire [7:0] memory_read_data;
    wire reset = ~button[0];
    // trace.ys connects these inputs to existing nets in the flattened CPU.
    wire [10:0] pc, sp;
    wire [2:0] state;
    wire [7:0] opcode, register_a, register_b, register_c, register_d;
    wire zero;

    prometheus_lite cpu (
        .clk(clk),
        .reset(reset),
        .memory_address(memory_address),
        .memory_read_enable(memory_read_enable),
        .memory_write_enable(memory_write_enable),
        .memory_write_data(memory_write_data),
        .memory_read_data(memory_read_data)
    );

    memory ram (
        .clk(clk),
        .address(memory_address),
        .memory_read_enable(memory_read_enable),
        .memory_write_enable(memory_write_enable),
        .write_data(memory_write_data),
        .read_data(memory_read_data)
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

    assign led = 5'b00000;

endmodule
