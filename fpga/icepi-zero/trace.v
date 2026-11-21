module icepi_trace (
    input wire clk, cpu_reset,
    input wire [98:0] probes,
    input wire jtck, jtdi, jce, jshift, jupdate, jrstn,
    output reg jtdo
);
    // ER1 DR: response = signature, address echo, done, ack, reserved, sample.
    // Request bits 10:0 = valid, reset trigger, arm, sample address.
    reg [119:0] scan;
    reg capture_dr, shift_dr, update_dr, selected;
    reg [7:0] read_address = 0;
    reg arm_request = 0;
    reg reset_trigger = 0;
    (* async_reg = "true" *) reg [2:0] arm_sync = 0;
    (* async_reg = "true" *) reg [1:0] trigger_sync = 0;
    reg arm_ack = 0;
    reg done = 0;
    (* async_reg = "true" *) reg [1:0] ack_sync = 0, done_sync = 0;

    localparam STOPPED = 0, WAIT_PRESS = 1, WAIT_RELEASE = 2, CAPTURE = 3;
    reg [1:0] capture_state = STOPPED;
    reg [7:0] write_address = 0;
    wire writing = capture_state == CAPTURE ||
                   (capture_state == WAIT_RELEASE && !cpu_reset);

    (* ram_style = "block" *) reg [98:0] samples [0:255];
    reg [98:0] sample;
    always @(posedge clk)
        if (writing)
            samples[write_address] <= probes;
    always @(posedge jtck)
        sample <= samples[read_address];

    always @(posedge clk) begin
        arm_sync <= {arm_sync[1:0], arm_request};
        trigger_sync <= {trigger_sync[0], reset_trigger};
        case (capture_state)
            STOPPED: if (arm_sync[2] != arm_ack) begin
                arm_ack <= arm_sync[2];
                done <= 0;
                write_address <= 0;
                if (trigger_sync[1])
                    capture_state <= cpu_reset ? WAIT_RELEASE : WAIT_PRESS;
                else
                    capture_state <= CAPTURE;
            end
            WAIT_PRESS: if (cpu_reset) capture_state <= WAIT_RELEASE;
            WAIT_RELEASE: if (!cpu_reset) begin
                write_address <= 1;
                capture_state <= CAPTURE;
            end
            CAPTURE: if (&write_address) begin
                capture_state <= STOPPED;
                done <= 1;
            end else begin
                write_address <= write_address + 1'b1;
            end
        endcase
    end

    // JTAGG presents registered control and TDI. Retiming the controls
    // aligns them with TDI and puts the shifter on the falling JTCK edge.
    always @(negedge jtck or negedge jrstn) begin
        if (!jrstn) begin
            selected <= 0;
            capture_dr <= 0;
            shift_dr <= 0;
            update_dr <= 0;
            scan <= 0;
        end else begin
            if (jce)
                selected <= 1;
            if (jupdate)
                selected <= 0;
            capture_dr <= jce && !jshift;
            shift_dr <= jshift && selected;
            update_dr <= jupdate && selected;
            if (capture_dr)
                scan <= {8'ha9, read_address, done_sync[1], ack_sync[1], 3'b0, sample};
            else if (shift_dr)
                scan <= {jtdi, scan[119:1]};
        end
    end

    always @(negedge jtck) begin
        if (jrstn && update_dr && scan[10]) begin
            read_address <= scan[7:0];
            if (scan[8] && arm_request == ack_sync[1]) begin
                arm_request <= ~arm_request;
                reset_trigger <= scan[9];
            end
        end
    end

    always @(posedge jtck) begin
        ack_sync <= {ack_sync[0], arm_ack};
        done_sync <= {done_sync[0], done};
        // The hard TAP also registers TDO on its falling edge.
        jtdo <= capture_dr ? sample[0] : shift_dr ? scan[1] : scan[0];
    end
endmodule
