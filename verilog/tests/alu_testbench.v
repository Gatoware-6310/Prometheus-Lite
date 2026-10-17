module alu_testbench;
    reg[7:0] a;
    reg[7:0] b;
    reg[7:0] opcode;

    wire[7:0] result;

    alu dut (
        .a(a),
        .b(b),
        .opcode(opcode),
        .result(result)
    );

    initial begin
        integer i; 
        a = 8'd100;
        b = 8'd23;
        opcode = 8'd0;

        for (i = 0; i < 6; i = i + 1) begin
            opcode = i;
            #10;
            $display("OPCODE: %d\nThe result was %d", opcode, result);
        end

        $finish;
    end

endmodule
