module uart_bridge #(
    parameter CLKS_PER_BIT = 434
) (
    input wire clk,
    input wire reset,
    input wire rx,
    output wire tx,
    output wire [7:0] ui,
    output reg [7:2] gpio_input = 0,
    input wire [7:0] uo,
    input wire [7:0] uio_out,
    input wire [7:0] uio_oe,
    output reg load = 0,
    output reg write_byte = 0,
    output reg reset_project = 0
);
    localparam TIMER_BITS = $clog2(CLKS_PER_BIT);
    localparam [7:0] ACK = 8'h06, NAK = 8'h15;
    reg [1:0] rx_sync = 2'b11;
    reg [TIMER_BITS-1:0] rx_timer = 0, tx_timer = 0;
    reg [3:0] rx_bit = 0, tx_bits = 0;
    reg [7:0] received = 0;
    reg rx_active = 0, received_byte = 0;
    reg [9:0] tx_shift = 10'h3ff;

    always @(posedge clk) begin
        rx_sync <= {rx_sync[0], rx};
        received_byte <= 0;
        if (reset) begin
            rx_active <= 0;
        end else if (!rx_active) begin
            if (!rx_sync[1]) begin
                rx_active <= 1;
                rx_timer <= CLKS_PER_BIT / 2 - 1;
                rx_bit <= 0;
            end
        end else if (rx_timer != 0) begin
            rx_timer <= rx_timer - 1'b1;
        end else begin
            rx_timer <= CLKS_PER_BIT - 1;
            rx_bit <= rx_bit + 1'b1;
            if (rx_bit == 0) begin
                if (rx_sync[1])
                    rx_active <= 0;
            end else if (rx_bit == 9) begin
                received_byte <= rx_sync[1];
                rx_active <= 0;
            end else begin
                received <= {rx_sync[1], received[7:1]};
            end
        end
    end

    reg [31:0] reply = 0;
    reg [2:0] reply_bytes = 0;
    reg [7:0] pending = 0;
    reg [11:0] loaded = 0;
    reg [7:0] runtime_input = 0, program_byte = 0;
    assign ui = load ? program_byte : runtime_input;
    assign tx = tx_shift[0];

    always @(posedge clk) begin
        write_byte <= 0;
        reset_project <= 0;
        if (reset) begin
            load <= 0;
            runtime_input <= 0;
            program_byte <= 0;
            gpio_input <= 0;
            pending <= 0;
            loaded <= 0;
            reply_bytes <= 0;
            tx_bits <= 0;
            tx_shift <= 10'h3ff;
        end else begin
            if (tx_bits != 0) begin
                if (tx_timer == 0) begin
                    tx_shift <= {1'b1, tx_shift[9:1]};
                    tx_timer <= CLKS_PER_BIT - 1;
                    tx_bits <= tx_bits - 1'b1;
                end else begin
                    tx_timer <= tx_timer - 1'b1;
                end
            end else if (reply_bytes != 0) begin
                tx_shift <= {1'b1, reply[7:0], 1'b0};
                tx_timer <= CLKS_PER_BIT - 1;
                tx_bits <= 10;
                reply <= reply >> 8;
                reply_bytes <= reply_bytes - 1'b1;
            end

            if (received_byte && tx_bits == 0 && reply_bytes == 0) begin
                reply <= {24'b0, ACK};
                reply_bytes <= 1;
                case (pending)
                    "W": begin
                        pending <= 0;
                        if (load && loaded < 3072) begin
                            program_byte <= received;
                            write_byte <= 1;
                            loaded <= loaded + 1'b1;
                        end else begin
                            reply <= {24'b0, NAK};
                        end
                    end
                    "I": begin
                        pending <= 0;
                        runtime_input <= received;
                    end
                    "G": begin
                        pending <= 0;
                        gpio_input <= received[7:2];
                    end
                    default: case (received)
                        "L": begin
                            load <= 1;
                            loaded <= 0;
                            reset_project <= 1;
                        end
                        "W", "I", "G": begin
                            pending <= received;
                            reply_bytes <= 0;
                        end
                        "R": load <= 0;
                        "X": begin
                            loaded <= 0;
                            reset_project <= 1;
                        end
                        "S": begin
                            reply <= {8'h00, uio_out & uio_oe, uo, ACK};
                            reply_bytes <= 3;
                        end
                        "P": begin
                            reply <= {uio_oe, uio_out & uio_oe, uo, ACK};
                            reply_bytes <= 4;
                        end
                        default: reply <= {24'b0, NAK};
                    endcase
                endcase
            end
        end
    end
endmodule
