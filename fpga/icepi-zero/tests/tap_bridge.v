`timescale 1ns/1ps
// Behavioral ECP5 TAP and JTAGG timing model for the host integration test.
module tap_bridge;
    localparam RESET=0, IDLE=1, SEL_DR=2, CAP_DR=3, SHIFT_DR=4, EXIT_DR=5,
               UPDATE_DR=6, SEL_IR=7, CAP_IR=8, SHIFT_IR=9, EXIT_IR=10, UPDATE_IR=11;
    reg clk=0, tck=0, tms=1, tdi=0;
    reg [3:0] state=RESET;
    reg [7:0] ir=8'he0, ir_shift=1;
    reg [31:0] id_shift=0;
    reg jtdi, user_tdo;
    wire jtdo;
    wire jce = ir == 8'h32 && (state == CAP_DR || state == SHIFT_DR);
    wire tdo = state == SHIFT_IR ? ir_shift[0] : ir == 8'h32 ? user_tdo : id_shift[0];

    reg [15:0] cycle=0;
    reg cpu_reset=0;
    reg [7:0] trigger_delay=0;
    wire [98:0] probes = {12'hb2e, 8'hd7, 8'hbc, 8'h92, cpu_reset, 8'hc2, 8'h81, 1'b1, 1'b0,
                         12'hb52, 1'b1, 8'h69, 8'h53, cycle[14:0]};
    icepi_trace dut(clk, cpu_reset, probes, tck, jtdi, jce, state == SHIFT_DR,
                    state == UPDATE_DR, state != RESET, jtdo);

    always #10 clk = ~clk;
    always @(posedge clk) begin
        cycle <= cycle + 1'b1;
        if (dut.capture_state != 1 && dut.capture_state != 2)
            trigger_delay <= 0;
        else
            trigger_delay <= trigger_delay + 1'b1;
        cpu_reset <= trigger_delay >= 10 && trigger_delay < 20;
    end
    always @(negedge tck)
        user_tdo <= jtdo;
    always @(posedge tck) begin
        jtdi <= tdi;
        case (state)
            RESET: begin ir <= 8'he0; state <= tms ? RESET : IDLE; end
            IDLE: state <= tms ? SEL_DR : IDLE;
            SEL_DR: state <= tms ? SEL_IR : CAP_DR;
            CAP_DR: begin id_shift <= 32'h41111043; state <= SHIFT_DR; end
            SHIFT_DR: begin
                id_shift <= {tdi, id_shift[31:1]};
                state <= tms ? EXIT_DR : SHIFT_DR;
            end
            EXIT_DR: state <= UPDATE_DR;
            UPDATE_DR: state <= tms ? SEL_DR : IDLE;
            SEL_IR: state <= tms ? RESET : CAP_IR;
            CAP_IR: begin ir_shift <= 1; state <= SHIFT_IR; end
            SHIFT_IR: begin
                ir_shift <= {tdi, ir_shift[7:1]};
                state <= tms ? EXIT_IR : SHIFT_IR;
            end
            EXIT_IR: state <= UPDATE_IR;
            UPDATE_IR: begin ir <= ir_shift; state <= tms ? SEL_DR : IDLE; end
            default: state <= RESET;
        endcase
    end

    integer bit_tms, bit_tdi, count;
    reg [63:0] line;
    initial begin
        forever begin
            count = $fgets(line, 'h80000000);
            if (!count) $finish;
            if ($sscanf(line, "%d %d", bit_tms, bit_tdi) != 2) $fatal;
            tms = bit_tms[0];
            tdi = bit_tdi[0];
            tck = 0;
            #55;
            $display("%b", tdo === 1'b1);
            $fflush();
            tck = 1;
            #55;
        end
    end
endmodule
