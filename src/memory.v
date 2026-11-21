/* Portable RAM for simulation and FPGA builds */

module memory(
    input wire clk,
    input wire memory_read_enable,
    input wire memory_write_enable,
    input wire [11:0] address,
    input wire [7:0] write_data,
    output wire [7:0] read_data,
    input wire fetch,
    output wire [23:0] instruction
);
    wire [9:0] row0, row1, row2;
    wire [2:0] enable, write_bank;
    reg [7:0] q0, q1, q2;

    memory_ports ports (
        .clk(clk), .address(address), .fetch(fetch),
        .read_byte(memory_read_enable), .write_byte(memory_write_enable),
        .row0(row0), .row1(row1), .row2(row2), .enable(enable), .write_bank(write_bank),
        .q0(q0), .q1(q1), .q2(q2), .read_data(read_data), .instruction(instruction)
    );

    (* ram_style = "distributed" *) reg [7:0] bank0 [0:1023];
    (* ram_style = "distributed" *) reg [7:0] bank1 [0:1023];
    (* ram_style = "distributed" *) reg [7:0] bank2 [0:1023];

`ifdef ICEPI_ZERO
    initial begin
        $readmemh("build/icepi/bank0.hex", bank0);
        $readmemh("build/icepi/bank1.hex", bank1);
        $readmemh("build/icepi/bank2.hex", bank2);
    end
`endif

    always @(posedge clk) if (enable[0]) begin
        if (write_bank[0]) bank0[row0] <= write_data;
        else q0 <= bank0[row0];
    end
    always @(posedge clk) if (enable[1]) begin
        if (write_bank[1]) bank1[row1] <= write_data;
        else q1 <= bank1[row1];
    end
    always @(posedge clk) if (enable[2]) begin
        if (write_bank[2]) bank2[row2] <= write_data;
        else q2 <= bank2[row2];
    end

`ifndef SYNTHESIS
    task load_byte(input integer addr, input [7:0] data);
        case (addr % 3)
            0: bank0[addr / 3] = data;
            1: bank1[addr / 3] = data;
            2: bank2[addr / 3] = data;
        endcase
    endtask

    function [7:0] peek_byte(input integer addr);
        case (addr % 3)
            0: peek_byte = bank0[addr / 3];
            1: peek_byte = bank1[addr / 3];
            2: peek_byte = bank2[addr / 3];
        endcase
    endfunction
`endif
endmodule

module memory_ports (
    input wire clk,
    input wire [11:0] address,
    input wire fetch, read_byte, write_byte,
    output wire [9:0] row0, row1, row2,
    output wire [2:0] enable, write_bank,
    input wire [7:0] q0, q1, q2,
    output wire [7:0] read_data,
    output reg [23:0] instruction
);
    function [1:0] nibble_mod3(input [3:0] nibble);
        case (nibble)
            1, 4, 7, 10, 13: nibble_mod3 = 1;
            2, 5, 8, 11, 14: nibble_mod3 = 2;
            default: nibble_mod3 = 0;
        endcase
    endfunction

    function [1:0] add_mod3(input [1:0] a, b);
        case ({a, b})
            4'h1, 4'h4, 4'ha: add_mod3 = 1;
            4'h2, 4'h5, 4'h8: add_mod3 = 2;
            default: add_mod3 = 0;
        endcase
    endfunction

    function [3:0] divide_digit(input [1:0] remainder, input [3:0] nibble);
        localparam [47:0] BIT0 = 48'he38e38e38e38;
        localparam [47:0] BIT1 = 48'hfc0fc0fc0fc0;
        localparam [47:0] BIT2 = 48'hfff000fff000;
        localparam [47:0] BIT3 = 48'hffffff000000;
        reg [5:0] digit;
        begin
            digit = {remainder, nibble};
            divide_digit = {BIT3[digit], BIT2[digit], BIT1[digit], BIT0[digit]};
        end
    endfunction

    // 16 mod 3 is 1, so each nibbles remainder can be computed combinationally
    wire [1:0] high_mod = nibble_mod3(address[11:8]);
    wire [1:0] mid_mod = add_mod3(high_mod, nibble_mod3(address[7:4]));
    wire [1:0] bank = add_mod3(mid_mod, nibble_mod3(address[3:0]));
    wire [3:0] row_high = divide_digit(2'd0, address[11:8]);
    wire [3:0] row_mid = divide_digit(high_mod, address[7:4]);
    wire [3:0] row_low = divide_digit(mid_mod, address[3:0]);
    wire [9:0] row = {row_high[1:0], row_mid, row_low};
    wire [9:0] next_row = row + 10'd1;
    wire valid = address < 12'hc00;
    wire [2:0] one_bank = 3'b001 << bank;
    wire [2:0] fetch_banks = {valid, address < 12'hbff, address < 12'hbfe};

    assign row0 = fetch && bank != 0 ? next_row : row;
    assign row1 = fetch && bank == 2 ? next_row : row;
    assign row2 = row;
    assign enable = fetch ? fetch_banks : valid && (read_byte || write_byte) ? one_bank : 3'b000;
    assign write_bank = !fetch && write_byte && !read_byte ? enable : 3'b000;

    reg [1:0] read_bank, fetch_bank;
    reg [2:0] fetched;
    always @(posedge clk) begin
        if (fetch) begin
            fetch_bank <= bank;
            fetched <= fetch_banks;
        end else if (read_byte)
            read_bank <= valid ? bank : 2'd3;
    end

    assign read_data = read_bank == 0 ? q0 : read_bank == 1 ? q1 : read_bank == 2 ? q2 : 8'h00;

    wire [7:0] byte0 = fetched[0] ? q0 : 8'h00;
    wire [7:0] byte1 = fetched[1] ? q1 : 8'h00;
    wire [7:0] byte2 = fetched[2] ? q2 : 8'h00;
    always @* begin
        case (fetch_bank)
            0: instruction = {byte0, byte1, byte2};
            1: instruction = {byte1, byte2, byte0};
            default: instruction = {byte2, byte0, byte1};
        endcase
    end
endmodule
