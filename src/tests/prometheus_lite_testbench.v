
`timescale 1ns/1ps
`define WAIT \
    repeat(7) @(negedge clk); // we wait for the falling edge 7 TIMES because the cpu does its work on the rising edge, and it has to do 7 cyces of work.
module prometheus_lite_testbench;

reg clk = 0;
reg reset = 0;
reg ir_enable = 0;
reg[23:0] instruction;

wire [11:0] memory_address;
wire memory_read_enable;
wire memory_write_enable;
wire [7:0] memory_write_data;
wire [7:0] memory_read_data;
wire memory_fetch;
wire [23:0] memory_instruction;


always #5 clk = ~clk;

prometheus_lite dut(
    .clk(clk),
    .reset(reset),
    .memory_address(memory_address),
    .memory_read_enable(memory_read_enable),
    .memory_write_enable(memory_write_enable),
    .memory_write_data(memory_write_data),
    .memory_read_data(memory_read_data),
    .memory_fetch(memory_fetch),
    .memory_instruction(memory_instruction)
);

memory ram(
    .clk(clk),
    .address(memory_address),
    .memory_read_enable(memory_read_enable),
    .memory_write_enable(memory_write_enable),
    .write_data(memory_write_data),
    .read_data(memory_read_data),
    .fetch(memory_fetch),
    .instruction(memory_instruction)
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
    ram.load_byte(0, 8'h00);
    ram.load_byte(1, 8'h01);
    ram.load_byte(2, 8'h3F);

    // Set the instruction to movr c, b
    ram.load_byte(3, 8'h01);
    ram.load_byte(4, 8'h02);
    ram.load_byte(5, 8'h01);

    // Set the instruction to mova 0x100
    ram.load_byte(6, 8'h02);
    ram.load_byte(7, 8'h01);
    ram.load_byte(8, 8'h00);

    // Set the instruction to movi a, 59
    ram.load_byte(9, 8'h00);
    ram.load_byte(10, 8'h00);
    ram.load_byte(11, 8'h3B);

    // Set the instruction to movfa 0x200
    ram.load_byte(12, 8'h06);
    ram.load_byte(13, 8'h02);
    ram.load_byte(14, 8'h00);

    // Move 0x02 into A
    ram.load_byte(15, 8'h00);
    ram.load_byte(16, 8'h00);
    ram.load_byte(17, 8'h02);


    // Move 0x00 into B
    ram.load_byte(18, 8'h00);
    ram.load_byte(19, 8'h01);
    ram.load_byte(20, 8'h0);
    // this makes the addres 0x200 in pair AB

    ram.load_byte(21, 8'h0A); //movp a, ab
    ram.load_byte(22, 8'h00);
    ram.load_byte(23, 8'h00);

    ram.load_byte(24, 8'h0B); //movfp a, ab
    ram.load_byte(25, 8'h00);
    ram.load_byte(26, 8'h00);

    // move 5 into a and b then add them together
    ram.load_byte(27, 8'h00);
    ram.load_byte(28, 8'h00);
    ram.load_byte(29, 8'h05);

    ram.load_byte(30, 8'h00);
    ram.load_byte(31, 8'h01);
    ram.load_byte(32, 8'h05);

    ram.load_byte(33, 8'h10);
    ram.load_byte(34, 8'h00);
    ram.load_byte(35, 8'h01);

    // subtract

    // move 3 into b
    ram.load_byte(36, 8'h00);
    ram.load_byte(37, 8'h01);
    ram.load_byte(38, 8'h03);

    ram.load_byte(39, 8'h12);
    ram.load_byte(40, 8'h00);
    ram.load_byte(41, 8'h01);

    // add 63 to D
    ram.load_byte(42, 8'h17);
    ram.load_byte(43, 8'h03);
    ram.load_byte(44, 8'h3F);

    // subtract 10 from D
    ram.load_byte(45, 8'h18);
    ram.load_byte(46, 8'h03);
    ram.load_byte(47, 8'h0A);

    // subtract 53 from D (for zero flag test)
    ram.load_byte(48, 8'h18);
    ram.load_byte(49, 8'h03);
    ram.load_byte(50, 8'h35);

    // jump to the 60
    ram.load_byte(51, 8'h30);
    ram.load_byte(52, 8'h00);
    ram.load_byte(53, 8'h3C);

    // move 63 into a
    ram.load_byte(60, 8'h00);
    ram.load_byte(61, 8'h00);
    ram.load_byte(62, 8'h3F);
    
    // move 2 into b
    ram.load_byte(63, 8'h00);
    ram.load_byte(64, 8'h01);
    ram.load_byte(65, 8'h02);
    
    // multiply a by b
    ram.load_byte(66, 8'h19);
    ram.load_byte(67, 8'h00);
    ram.load_byte(68, 8'h01);
    
    // move 126 into b
    ram.load_byte(69, 8'h00);
    ram.load_byte(70, 8'h01);
    ram.load_byte(71, 8'h7E);

    // compare a and b
    ram.load_byte(72, 8'h16);
    ram.load_byte(73, 8'h00);
    ram.load_byte(74, 8'h01);

    // jump if zero flag, to address 100
    ram.load_byte(75, 8'h31);
    ram.load_byte(76, 8'h00);
    ram.load_byte(77, 8'h64);

    // move 63 into a, 10 into b
    ram.load_byte(78, 8'h00);
    ram.load_byte(79, 8'h00);
    ram.load_byte(80, 8'h3F);

    ram.load_byte(81, 8'h00);
    ram.load_byte(82, 8'h00);
    ram.load_byte(83, 8'h0A);

    // AND
    ram.load_byte(100, 8'h20);
    ram.load_byte(101, 8'h00);
    ram.load_byte(102, 8'h01);

    // OR
    ram.load_byte(103, 8'h21);
    ram.load_byte(104, 8'h00);
    ram.load_byte(105, 8'h01);

    // XOR
    ram.load_byte(106, 8'h22);
    ram.load_byte(107, 8'h00);
    ram.load_byte(108, 8'h01);

    // NOT
    ram.load_byte(109, 8'h23);
    ram.load_byte(110, 8'h00);
    ram.load_byte(111, 8'h00);

    // SHL
    ram.load_byte(112, 8'h24);
    ram.load_byte(113, 8'h00);
    ram.load_byte(114, 8'h00);

    // SHR
    ram.load_byte(115, 8'h25);
    ram.load_byte(116, 8'h00);
    ram.load_byte(117, 8'h00);

    // JNZ
    ram.load_byte(118, 8'h32);
    ram.load_byte(119, 8'h00);
    ram.load_byte(120, 8'h97); // this should jump to 151

    // move 182 into ab
    ram.load_byte(151, 8'h00);
    ram.load_byte(152, 8'h00);
    ram.load_byte(153, 8'h00);

    ram.load_byte(154, 8'h00);
    ram.load_byte(155, 8'h01);
    ram.load_byte(156, 8'hB6);

    // JMPP ab, to 182
    ram.load_byte(157, 8'h35);
    ram.load_byte(158, 8'h00);
    ram.load_byte(159, 8'h00);

    // move 63 into a
    ram.load_byte(182, 8'h00);
    ram.load_byte(183, 8'h00);
    ram.load_byte(184, 8'h3F);

    // push a (63)
    ram.load_byte(185, 8'h40);
    ram.load_byte(186, 8'h00);
    ram.load_byte(187, 8'h00);

    // move 99 into b
    ram.load_byte(188, 8'h00);
    ram.load_byte(189, 8'h01);
    ram.load_byte(190, 8'h63);

    // push b (99)
    ram.load_byte(191, 8'h40);
    ram.load_byte(192, 8'h01);
    ram.load_byte(193, 8'h00);

    // pop into c (should be 99)
    ram.load_byte(194, 8'h41);
    ram.load_byte(195, 8'h02);
    ram.load_byte(196, 8'h00);

    // pop into d (should be 63)
    ram.load_byte(197, 8'h41);
    ram.load_byte(198, 8'h03);
    ram.load_byte(199, 8'h00);

    // move 230 into ab
    ram.load_byte(200, 8'h00);
    ram.load_byte(201, 8'h00);
    ram.load_byte(202, 8'h00);

    ram.load_byte(203, 8'h00);
    ram.load_byte(204, 8'h01);
    ram.load_byte(205, 8'hE6);

    // compare c and c to set zero flag
    ram.load_byte(206, 8'h16);
    ram.load_byte(207, 8'h02);
    ram.load_byte(208, 8'h02);

    // jnzp ab, should not jump
    ram.load_byte(209, 8'h37);
    ram.load_byte(210, 8'h00);
    ram.load_byte(211, 8'h00);

    // jzp ab, to 230
    ram.load_byte(212, 8'h36);
    ram.load_byte(213, 8'h00);
    ram.load_byte(214, 8'h00);

    // move 260 into ab
    ram.load_byte(230, 8'h00);
    ram.load_byte(231, 8'h00);
    ram.load_byte(232, 8'h01);

    ram.load_byte(233, 8'h00);
    ram.load_byte(234, 8'h01);
    ram.load_byte(235, 8'h04);

    // compare c and d to clear zero flag
    ram.load_byte(236, 8'h16);
    ram.load_byte(237, 8'h02);
    ram.load_byte(238, 8'h03);

    // jzp ab, should not jump
    ram.load_byte(239, 8'h36);
    ram.load_byte(240, 8'h00);
    ram.load_byte(241, 8'h00);

    // jnzp ab, to 260
    ram.load_byte(242, 8'h37);
    ram.load_byte(243, 8'h00);
    ram.load_byte(244, 8'h00);

    // halt
    ram.load_byte(260, 8'h53);
    ram.load_byte(261, 8'h00);
    ram.load_byte(262, 8'h00);

    // put a number into the memory address, 0x100
    ram.load_byte(256, 255);

    ram.load_byte(3071, 67); // last index

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
    if(ram.peek_byte(512) == 59)
        $display("MOVE BYTE FROM REGISTER INTO MEMORY %d, [PASS]", ram.peek_byte(512));
    else
        $fatal(1, "MOVE BYTE FROM REGISTER INTO MEMORY %d, [FAIL]", ram.peek_byte(512));

    wait(dut.value_pc == 24);
    @(negedge clk)
    if(dut.rf.registers[0] == 59)
        $display("MOVE BYTE FROM MEMORY POINTED TO BY REGISTER PAIR INTO REGISTER %d [PASS]", dut.rf.registers[0]);
    else 
        $fatal(1, "MOVE BYTE FROM MEMORY POINTED TO BY REGISTER PAIR INTO REGISTER %d [FAIL]", dut.rf.registers[0]);

    wait(dut.value_pc == 27);
    @(negedge clk)
    if(ram.peek_byte(2816) == 59)
        $display("MOVE BYTE FROM REGISTER TO MEMORY POINTED TO BY REGISTER PAIR %d [PASS]", ram.peek_byte(2816));
    else 
        $fatal(1, "MOVE BYTE FROM REGISTER TO MEMORY POINTED TO BY REGISTER PAIR %d [FAIL]", ram.peek_byte(2816));

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

    wait(dut.value_pc == 60);
    @(negedge clk)
    if(dut.value_pc == 60)
        $display("JUMP TEST %d [PASS]", dut.value_pc);
    else
        $fatal(1, "JUMP TEST %d [FAIL]", dut.value_pc); // this if statement is probably useless because it'll time out if the wait doesn't work, but eh
    
    wait(dut.value_pc == 69);
    @(negedge clk)
    if(dut.rf.registers[0] == 126)
        $display("MULTIPLY TEST %d [PASS]", dut.rf.registers[0]);
    else
        $fatal(1, "MULTIPLY TEST %d [PASS]", dut.rf.registers[0]);

    wait(dut.value_pc == 100); // wait until it jumps to 100, which it should. increments by 3, meaning it won't hit 100 naturally
    @(negedge clk)
    if(dut.value_pc == 100)
        $display("COMPARE / JUMP IF ZERO TEST %d [PASS]", dut.value_pc);
    else
        $fatal(1, "JUMP IF ZERO TEST %d [FAIL]", dut.value_pc); // this if statement is probably useless because it'll time out if the wait doesn't work, but eh
    
    wait(dut.value_pc == 118)
    if(dut.rf.registers[0] == 127)
        $display("AND, OR, XOR, NOT, SHL, SHR TEST %d [PASS]", dut.rf.registers[0]);
    else
        $fatal(1, "AND, OR, XOR, NOT, SHL, SHR TEST %d [FAIL]", dut.rf.registers[0]);

    wait(dut.value_pc == 151); // it won't hit this naturally
    @(negedge clk)
    if(dut.value_pc == 151)
        $display("JUMP IF NOT ZERO TEST %d [PASS]", dut.value_pc);
    else
        $fatal(1, "JUMP IF NOT ZERO TEST %d [FAIL]", dut.value_pc); // same same

    wait(dut.value_pc == 182); // same same
    @(negedge clk)
    if(dut.value_pc == 182)
        $display("JUMP FROM POINTER IN REGISTER PAIR %d [PASS]", dut.value_pc);
    else
        $fatal(1, "JUMP FROM POINTER IN REGISTER PAIR %d [FAIL]", dut.value_pc); // same same x2

    wait(dut.value_pc == 200);
    @(negedge clk)
    if(dut.rf.registers[2] == 99 && dut.rf.registers[3] == 63)
        $display("PUSH/POP STACK TEST %d %d [PASS]", dut.rf.registers[2], dut.rf.registers[3]);
    else
        $fatal(1, "PUSH/POP STACK TEST %d %d [PASS]", dut.rf.registers[2], dut.rf.registers[3]);
    
    wait(dut.value_pc == 212);
    @(negedge clk)
    if(dut.value_pc == 212)
        $display("JUMP IF NOT ZERO FROM POINTER %d [PASS]", dut.value_pc);
    else
        $fatal(1, "JUMP IF NOT ZERO FROM POINTER %d [FAIL]", dut.value_pc);

    wait(dut.value_pc == 230);
    @(negedge clk)
    if(dut.value_pc == 230)
        $display("JUMP IF ZERO FROM POINTER %d [PASS]", dut.value_pc);
    else
        $fatal(1, "JUMP IF ZERO FROM POINTER %d [FAIL]", dut.value_pc);

    wait(dut.value_pc == 242);
    @(negedge clk)
    if(dut.value_pc == 242)
        $display("JUMP IF ZERO FROM POINTER %d [PASS]", dut.value_pc);
    else
        $fatal(1, "JUMP IF ZERO FROM POINTER %d [FAIL]", dut.value_pc);

    wait(dut.value_pc == 260);
    @(negedge clk)
    if(dut.value_pc == 260)
        $display("JUMP IF NOT ZERO FROM POINTER %d [PASS]", dut.value_pc);
    else
        $fatal(1, "JUMP IF NOT ZERO FROM POINTER %d [FAIL]", dut.value_pc);

    wait(dut.state == dut.HALT); // wait till halted
    $display("HALT TEST [PASS]"); // there's no way we get here unless it's halted so i'm just gonna be lazy

    $display("ALL TESTS PASSSSSSSSSSSSSSSSSSSS!!!");
    $finish;    
end

initial begin
    // dump it!
    $dumpfile("build/gtkwave/dump.vcd");
    $dumpvars(0, prometheus_lite_testbench);
end

initial begin
    #1000000;
    $fatal(1, "TEST TIMEOUT. PC: %d, ZERO: %d", dut.value_pc, dut.zero);
end

endmodule
