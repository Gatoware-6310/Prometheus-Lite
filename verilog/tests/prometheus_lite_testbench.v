
`timescale 1ns/1ps
`define WAIT \
    repeat(7) @(negedge clk); // we wait for the falling edge 7 TIMES because the cpu does its work on the rising edge, and it has to do 7 cyces of work.
module prometheus_lite_testbench;

reg clk = 0;
reg reset = 0;
reg ir_enable = 0;
reg[23:0] instruction;

always #5 clk = ~clk;

prometheus_lite dut(
    .clk(clk),
    .reset(reset)
);

/*
always @(posedge clk) begin // FOR HEAVIER DEBUGGING
    if (!reset)
        $display("State: %d, Next State: %d, Current: %0xh",
                 $time, dut.state, dut.next_state, dut.opcode);
end
*/

initial begin
    $display("--------- Resetting the CPU ---------\n");
    // Reset the cpu first
    reset = 1;

    // Set the instruction to movi b, 63
    dut.ram.memory[0] = 8'h00;
    dut.ram.memory[1] = 8'h01;
    dut.ram.memory[2] = 8'h3F;

    // Set the instruction to movr c, b
    dut.ram.memory[3] = 8'h01;
    dut.ram.memory[4] = 8'h02;
    dut.ram.memory[5] = 8'h01;

    // Set the instruction to mova 0x100
    dut.ram.memory[6] = 8'h02;
    dut.ram.memory[7] = 8'h01;
    dut.ram.memory[8] = 8'h00;

    // Set the instruction to movi a, 63
    dut.ram.memory[9] = 8'h00;
    dut.ram.memory[10] = 8'h00;
    dut.ram.memory[11] = 8'h3F;

    // Set the instruction to movfa 0x200
    dut.ram.memory[12] = 8'h06;
    dut.ram.memory[13] = 8'h02;
    dut.ram.memory[14] = 8'h00;

    // Move 0x02 into A
    dut.ram.memory[15] = 8'h00;
    dut.ram.memory[16] = 8'h00;
    dut.ram.memory[17] = 8'h02;


    // Move 0x00 into B
    dut.ram.memory[18] = 8'h00;
    dut.ram.memory[19] = 8'h01;
    dut.ram.memory[20] = 8'h0;
    // this makes the addres 0x200 in pair AB

    dut.ram.memory[21] = 8'h0A; //movp a, ab
    dut.ram.memory[22] = 8'h00;
    dut.ram.memory[23] = 8'h00;

    dut.ram.memory[24] = 8'h0B; //movfp a, ab
    dut.ram.memory[25] = 8'h00;
    dut.ram.memory[26] = 8'h00;

    // move 5 into a and b then add them together
    dut.ram.memory[27] = 8'h00;
    dut.ram.memory[28] = 8'h00;
    dut.ram.memory[29] = 8'h05;

    dut.ram.memory[30] = 8'h00;
    dut.ram.memory[31] = 8'h01;
    dut.ram.memory[32] = 8'h05;

    dut.ram.memory[33] = 8'h10;
    dut.ram.memory[34] = 8'h00;
    dut.ram.memory[35] = 8'h01;

    // subtract

    // move 3 into b
    dut.ram.memory[36] = 8'h00;
    dut.ram.memory[37] = 8'h01;
    dut.ram.memory[38] = 8'h03;

    dut.ram.memory[39] = 8'h12;
    dut.ram.memory[40] = 8'h00;
    dut.ram.memory[41] = 8'h01;

    // add 63 to D
    dut.ram.memory[42] = 8'h17;
    dut.ram.memory[43] = 8'h03;
    dut.ram.memory[44] = 8'h3F;

    // subtract 10 from D
    dut.ram.memory[45] = 8'h18;
    dut.ram.memory[46] = 8'h03;
    dut.ram.memory[47] = 8'h0A;

    // subtract 53 from D (for zero flag test)
    dut.ram.memory[48] = 8'h18;
    dut.ram.memory[49] = 8'h03;
    dut.ram.memory[50] = 8'h35;

    // jump to the start
    dut.ram.memory[51] = 8'h30;
    dut.ram.memory[52] = 8'h00;
    dut.ram.memory[53] = 8'h3C;

    // move 63 into a
    dut.ram.memory[60] = 8'h00;
    dut.ram.memory[61] = 8'h00;
    dut.ram.memory[62] = 8'h3F;

    // subtract 63 from a
    dut.ram.memory[63] = 8'h18;
    dut.ram.memory[64] = 8'h00;
    dut.ram.memory[65] = 8'h3F;

    // jump if zero flag
    dut.ram.memory[66] = 8'h31;
    dut.ram.memory[67] = 8'h00;
    dut.ram.memory[68] = 8'h00;

    // put a number into the memory address, 0x100
    dut.ram.memory[256] = 255;

    dut.ram.memory[2047] = 67; // last index

    `WAIT
    reset = 0;
    $display("--------- Successful! Probably ---------\n");

    $display("--------- Instruction tests ---------\n");

    wait(dut.value_pc == 3); // wait until we're done executing that instruction
    @(negedge clk); // wait until the work is done for sure
    if(dut.rf.registers[1] == 63)
        $display("MOVE IMMEDIATE %d, [PASS]", dut.rf.registers[1]);
    else $fatal(1, "MOVE IMMEDIATE %d, [FAIL]", dut.rf.registers[1]);

    wait(dut.value_pc == 6);
    @(negedge clk);
    if(dut.rf.registers[2] == 63)
        $display("MOVE REGISTERS %d, [PASS]", dut.rf.registers[2]);
    else $fatal(1, "MOVE REGISTERS %d, [FAIL]", dut.rf.registers[2]);

    wait(dut.value_pc == 9);
    @(negedge clk);
    if(dut.rf.registers[0] == 255)
        $display("MOVE MEMORY INTO REGISTER %d, [PASS]", dut.rf.registers[0]);
    else $fatal(1, "MOVE MEMORY INTO REGISTER %d, [FAIL]", dut.rf.registers[0]);

    wait(dut.value_pc == 15);
    @(negedge clk)
    if(dut.ram.memory[512] == 63)
        $display("MOVE BYTE FROM REGISTER INTO MEMORY %d, [PASS]", dut.ram.memory[512]);
    else
        $fatal(1, "MOVE BYTE FROM REGISTER INTO MEMORY %d, [FAIL]", dut.ram.memory[512]);

    wait(dut.value_pc == 24);
    @(negedge clk)
    if(dut.rf.registers[0] == 63)
        $display("MOVE BYTE FROM MEMORY POINTED TO BY REGISTER PAIR INTO REGISTER %d [PASS]", dut.rf.registers[0]);
    else 
        $fatal(1, "MOVE BYTE FROM MEMORY POINTED TO BY REGISTER PAIR INTO REGISTER %d [FAIL]", dut.rf.registers[0]);

    wait(dut.value_pc == 27);
    @(negedge clk)
    if(dut.ram.memory[1792] == 63)
        $display("MOVE BYTE FROM REGISTER TO MEMORY POINTED TO BY REGISTER PAIR %d [PASS]", dut.ram.memory[1792]);
    else 
        $fatal(1, "MOVE BYTE FROM REGISTER TO MEMORY POINTED TO BY REGISTER PAIR %d [FAIL]", dut.ram.memory[1008]);

    wait(dut.value_pc == 36);
    @(negedge clk)
    if(dut.rf.registers[0] == 10)
        $display("ADD REGISTER TO REGISTER %d [PASS]", dut.rf.registers[0]);
    else
        $fatal(1, "ADD REGISTER TO REGISTER %d [FAIL]", dut.rf.registers[0]);

    wait(dut.value_pc == 42);
    @(negedge clk)
    if(dut.rf.registers[0] == 7)
        $display("SUBTRACT REGISTER FROM REGISTER %d [PASS]", dut.rf.registers[0]);
    else
        $fatal(1, "SUBTRACT REGISTER FROM REGISTER %d [FAIL]", dut.rf.registers[0]);

    wait(dut.value_pc == 45);
    @(negedge clk)
    if(dut.rf.registers[3] == 63)
        $display("ADD IMMEDIATE VALUE TO REGISTER %d [PASS]", dut.rf.registers[3]);
    else
        $fatal(1, "ADD IMMEDIATE VALUE TO REGISTER %d [FAIL]", dut.rf.registers[3]);

    wait(dut.value_pc == 48);
    @(negedge clk)
    if(dut.rf.registers[3] == 53)
        $display("SUBTRACT IMMEDIATE VALUE FROM REGISTER %d [PASS]", dut.rf.registers[3]);
    else
        $fatal(1, "SUBTRACT IMMEDIATE VALUE FROM REGISTER %d [FAIL]", dut.rf.registers[3]);

    wait(dut.value_pc == 51);
    @(negedge clk)
    if(dut.zero)
        $display("ZERO FLAG TEST %d [PASS]", dut.zero);
    else
        $fatal(1, "ZERO FLAG TEST %d [FAIL]", dut.zero, dut.rf.registers[3]);

    wait(dut.value_pc == 60); // wait until it jumps to 0, which it will
    @(negedge clk)
    if(dut.value_pc == 60)
        $display("JUMP TEST %d [PASS]", dut.value_pc);
    else
        $fatal(1, "JUMP TEST %d [FAIL]", dut.value_pc); // this if statement is probably useless because it'll time out if the wait doesn't work, but eh

    wait(dut.value_pc == 0); // wait until it jumps to 0, which it will
    @(negedge clk)
    if(dut.value_pc == 0)
        $display("JUMP IF ZERO TEST %d [PASS]", dut.value_pc);
    else
        $fatal(1, "JUMP IF ZERO TEST %d [FAIL]", dut.value_pc); // this if statement is probably useless because it'll time out if the wait doesn't work, but eh


    $display("Resetting the CPU...");
    reset = 1;
    `WAIT
    reset = 0;
    $display("--------- Successful! Probably ---------\n");

    $display("--------- Program Start ---------\n");

    $readmemh("../assembler/hex_test.bin", dut.ram.memory);
    repeat (2048) @(negedge clk);
    $display("Program finished execution!");
    $display("REGISTERS:");
    $display("A: %d, B: %d, C: %d, D: %d", dut.rf.registers[0], dut.rf.registers[1], dut.rf.registers[2], dut.rf.registers[3]);
    $display("FLAGS:");
    $display("Zero: ", dut.zero);
    $finish;
end

initial begin
    #1000000;
    $fatal(1, "TEST TIMEOUT");
end

endmodule
