# Prometheus Lite
A smaller, less ambitious 8 bit version of my Prometheus CPU.

## ISA

### 1. Architecture specifications

Prometheus Lite will have:

- An 8 bit data width
- 16 bit address space (byte addressed)
- Fixed 24 bit (3 byte) instruction width
- 4 general purpose registers (A, B, C, and D)
- 2 register pairs for pointers and 16 bit values (AB and CD)
- A 256 byte downward stack (8 bit stack pointer)
- A Zero flag (Z) and a Carry flag (C)
- Big Endian ordering for 16 bit operands in some instructions
- No native signed integer support!

## 2. Registers

### General-purpose registers

Prometheus Lite contains four 8 bit general purpose registers;

| Register | Encoding |
|---|---|---|
| A | `0x00` |
| B | `0x01` |
| C | `0x02` |
| D | `0x03` |

### Register pairs

Two big endian 16 bit register pairs are available.

| Pair | Encoding |
|---|---|
| AB | `0x00` |
| CD | `0x01` |

Register pairs are not additional storage, they are simply the value of two registers concateated.

### Super Secret Special registers

**Program Counter**

- Contains the address of the current instruction
- Advances by 3 bytes
- Can be modified by jumps of any kind
- 16 bit!

**Stack Pointer**

- 8 bit register
- Resets to `0xFF`
- Grows downward
- Occupies `0x0000` to `0x00FF` in order to work with basically any memory limit

**Instruction Register**

- Takes in a 24 bit instruction, returns 3 bytes - the opcode, first operand, and second operand

## 3. Instruction encoding

Every instruction occupies 3 bytes, even if it doesn't use all 3.

| Byte | Content |
|---|---|
| 0 | Opcode |
| 1 | Operand 1 |
| 2 | Operand 2 |

Operands unused by the current instruction are ignored.

Byte 0 is considered the first byte left to right, so in `AB CD EF`, the first byte would be `AB`.

Similarly, in 111111110000000101010101, `11111111` would be the first byte, or opcode.

### Example encodings

`movi a, 42`

- Opcode: `0x00`
- Register A: `0x00`
- Immediate 42: `0x2A`

Machine code: `00 00 2A`

`movi d, 255`

Machine code: `00 03 FF`

`mova 0x1234`

Machine code: `02 12 34`

`add a, b`

Machine code: `10 00 01`

`mul a, b`

Machine code: `19 00 01`

`jmp 0x4000`

Machine code: `30 40 00`

## 4. Processor flags

The CPU implements two flags.

| Flag | Description |
|---|---|
| Z | Zero flag |
| C | Carry flag |

### Zero flag (Z)

Set when an instruction that updates flags produces a result equal to zero. For example, `dec a` if `a` contains 1, or `cmp a, b` if `a` and `b` contain the same value.

- `Z = 1`: The result was zero
- `Z = 0`: the result was not zero

### Carry flag (C)

Used for unsigned multi-byte operations;

**Addition:**

- `C = 1` when the result exceeds 255
- `C = 0` when the result does not exceed 255

**Subtraction:**

- `C = 1` when no borrow occurs
- `C = 0` when a borrow occurs

**Increment:**

- `C = 1` when incrementing `0xFF` to `0x00`
- `C = 0` when... not doing that

**Decrement:**

- `C = 1` when decrementing `0x00` to `0xFF`
- `C = 0` I think you get the gist of it

**Shifts:**

- C receives the bit shifted out of the register.

### Flag modification table

| Instructions                | Zero Flag (Z)             | Carry Flag (C)                       |
| --------------------------- | ------------------------- | ------------------------------------ |
| `add`, `addi`, `adc`        | Set only if the result is zero | Set if the addition produces a carry |
| `sub`, `subi`, `sbc`, `cmp` | Set only if the result is zero | Set if no borrow was needed          |
| `mul`                       | Set only if the result is zero | Set if the product exceeds 255 |
| `inc`                       | Set only if the result is zero | Set if incrementing 255 |
| `dec`                       | Set only if the result is zero | Set if decrementing 0 |
| `and`, `or`, `xor`, `not`   | Set only if the result is zero | Not affected                         |
| `shl`, `shr`                | Set only if the result is zero | Stores the bit that was shifted out  |
| `clc`                       | Not affected              | Cleared to 0                         |
| `sec`                       | Not affected              | Set to 1                             |

## 5. Instruction set

### 5.1 Data movement

| Opcode | Instruction | Description |
|---|---|---|
| `0x00` | `movi register, imm` | Move immediate value into register |
| `0x01` | `movr destination, source` | Copy register to register |
| `0x02` | `mova address` | Move memory into A |
| `0x03` | `movb address` | Move memory into B |
| `0x04` | `movc address` | Move memory into C |
| `0x05` | `movd address` | Move memory into D |
| `0x06` | `movfa address` | *Move from* A into memory |
| `0x07` | `movfb address` | *Move from* B into memory |
| `0x08` | `movfc address` | *Move from* C into memory |
| `0x09` | `movfd address` | *Move from* D into memory |
| `0x0A` | `ldi destination, pair` | Load memory through register pair |
| `0x0B` | `sti pair, source` | Store memory through register pair |

For example;

`mova 0x1234` loads the byte at address `0x1234` into A, `movfa 0x1234` stores A at address `0x1234`,

And;

`ldi c, ab` loads the byte at the address held in AB into C, `sti ab, c` stores C at the address held in AB.

### 5.2 Arithmetic

| Opcode | Instruction | Description |
|---|---|---|
| `0x10` | `add dst, src` | Add source register |
| `0x11` | `adc dst, src` | Add source register with carry |
| `0x12` | `sub dst, src` | Subtract source register |
| `0x13` | `sbc dst, src` | Subtract source register with borrow |
| `0x14` | `inc r` | Increment register |
| `0x15` | `dec r` | Decrement register |
| `0x16` | `cmp dst, src` | Compare registers |
| `0x17` | `addi r, imm` | Add immediate value |
| `0x18` | `subi r, imm` | Subtract immediate value |
| `0x19` | `mul dst, src` | Multiply registers, keeping the low 8 bits of the result |

### 5.3 Logic and shifts

| Opcode | Instruction | Description |
|---|---|---|
| `0x20` | `and dst, src` | Bitwise AND |
| `0x21` | `or dst, src` | Bitwise OR |
| `0x22` | `xor dst, src` | Bitwise XOR |
| `0x23` | `not r` | Bitwise NOT |
| `0x24` | `shl r` | Shift left |
| `0x25` | `shr r` | Shift right |

### 5.4 Jumping

| Opcode | Instruction | Description |
|---|---|---|
| `0x30` | `jmp addr` | Unconditional jump |
| `0x31` | `jz addr` | Jump if Z = 1 |
| `0x32` | `jnz addr` | Jump if Z = 0 |
| `0x33` | `jc addr` | Jump if C = 1 |
| `0x34` | `jnc addr` | Jump if C = 0 |
| `0x35` | `jmpab` | Jump to the address in AB |
| `0x36` | `jmpcd` | Jump to the address in CD |

### 5.5 Stack and calling

| Opcode | Instruction | Description |
|---|---|---|
| `0x40` | `push r` | Push the register onto stack |
| `0x41` | `pop r` | Pop a byte from the stack into the register |
| `0x42` | `call addr` | Call a function |
| `0x43` | `ret` | Return from the function |

**PUSH**

Decrements SP by 1, and *then* stores the value at the address of SP.

**POP**

Reads the memory from address SP into the destination register, and *then* increments SP by 1.

`call`/`ret` do not save flags.

### 5.6 Flag/system operations

| Opcode | Instruction | Description |
|---|---|---|
| `0x50` | `clc` | Clear the carry flag |
| `0x51` | `sec` | Set the carry flag to 1 |
| `0x52` | `nop` | Nothing! |
| `0x53` | `hlt` | Stops execution |

## 6. Instruction execution and PC behavior

The program counter is 16 bits wide.

During normal execution, the program counter is incremented by **3** every clock.

If the PC ever overflows, it is reset to 0.

## 7. Assembly examples

### Load an immediate

```asm
movi a, 42
movi b, 10
add a, b
hlt
```

Result: `A` = 52.

### Multiply registers

```asm
movi a, 12
movi b, 10
mul a, b
hlt
```

`A` contains the result of the product (120). `Z` is set if that result is zero, and `C` is set if the result exceeds 255.

### Load from memory

```asm
mova 0x1234
```

`A` receives the byte stored at address `0x1234`.

### Indirect memory access

```asm
movi a, 0x40
movi b, 0x80

ldi c, ab
```

`C` receives the byte stored at address `0x4080`.

### Increment a 16-bit pointer

```asm
inc b
jnc done
inc a

done:
```

If `B` overflows, `A` is incremented.

### Unsigned comparison

```asm
movi a, 10
movi b, 20

cmp a, b
jc greater_or_equal

hlt

greater_or_equal:
    nop
    hlt
```

Because 10 is less than 20, `C` is cleared and the jump is not taken.

### 16-bit addition

```asm
; AB = first 16 bit number
; CD = second 16 bit number

clc
adc b, d
adc a, c
```

The 16 bit result is stored in `AB`.

### Subroutine call

```asm
movi a, 10
call double
hlt

double:
    add a, a
    ret
```

`A` contains 20 after the subroutine returns.

## NOTES
- Prometheus Lite is now a DUAL CYCLE CPU, with a FETCH and EXECUTE cycle. Fetch includes decoding the instruction and execute includes memory/register writeback, etc.

## The end!

**Prometheus Lite ISA v1.0**

Designed for a compact, high frequency, 8 bit ASIC CPU.