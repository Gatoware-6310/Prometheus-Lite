# Prometheus Lite
A smaller, less ambitious 8 bit version of my Prometheus CPU.

## ISA

### 1. Architecture specifications

Prometheus Lite will have:

- An 8 bit data width
- 11 bit address space (byte addressed)
- Fixed 24 bit (3 byte) instruction width
- 4 general purpose registers (A, B, C, and D)
- 2 register pairs for pointers and 16 bit values (AB and CD)
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

Addresses are 11 bits (`0x000` to `0x7FF`). For pointers, only the lowest 3 bits of the first register in a pair are used.

### Super Secret Special registers

**Program Counter**

- Contains the address of the current instruction
- Advances by 3 bytes
- Can be modified by jumps of any kind
- 11 bit!


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

`add a, b`

Machine code: `10 00 01`

`mul a, b`

Machine code: `19 00 01`

## 4. Processor flags

| Flag | Description |
|---|---|
| Z | Zero flag |

### Zero flag (Z)

Set when an instruction that updates flags produces a result equal to zero. For example, `dec a` if `a` contains 1, or `cmp a, b` if `a` and `b` contain the same value.

- `Z = 1`: The result was zero
- `Z = 0`: the result was not zero

`add`, `sub`, `addi`, `subi`, `cmp`, `mul`, `and`, `or`, `xor`, `not`, `shl`, and `shr` update Z. `inc` and `dec` update it too!

Z isn’t explicitly reset. For `mul`, Z is based on the low 8 bits of the result.

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
| `0x0A` | `movp destination, pair` | Move memory into the destination register from the pointer in the register pair |
| `0x0B` | `movfp pair, source` | Store the value of a register into the pointer in the register pair |

For example;

`movp c, ab` loads the byte at the address held in AB into C, `movfp ab, c` stores C at the address held in AB.

### 5.2 Arithmetic

| Opcode | Instruction | Description |
|---|---|---|
| `0x10` | `add dst, src` | Add source register |
| `0x12` | `sub dst, src` | Subtract source register |
| Macro | `inc r` | Increment register (assembled as `addi r, 1`) |
| Macro | `dec r` | Decrement register (assembled as `subi r, 1`) |
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
| `0x35` | `jmpp pair` | Jump to the address in the register pair |

### 5.5 Stack

| Opcode | Instruction | Description |
|---|---|---|
| `0x40` | `push r` | Push the register onto stack |
| `0x41` | `pop r` | Pop a byte from the stack into the register |

SP is 11 bits, resets to `0x7FF`, and grows downward.

`push` stores at SP, then decrements it. `pop` increments SP, then reads from it.

### 5.6 Flag/system operations

| Opcode | Instruction | Description |
|---|---|---|
| `0x52` | `nop` | Nothing! |
| `0x53` | `hlt` | Stops execution |

## 6. Instruction execution and PC behavior

The program counter is 11 bits wide. During normal execution, it advances by **3** during register writeback. If it’s `0x7FD` or higher when incremented, it resets to 0.

## 7. Assembly examples

The assembler accepts decimal immediates and numeric addresses. It doesn’t support blank lines, comments, or labels yet!

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

`A` contains the result of the product (120). `Z` is set if that result is zero.

### Load from memory

`mova 0x234` loads the byte at address `0x234` into A.

### Indirect memory access

```asm
movi a, 4
movi b, 128
movp c, ab
```

`C` receives the byte stored at address `0x480`.

## NOTES
- Prometheus Lite is now a multi cycle CPU, with FETCH_A, FETCH_B, FETCH_C, FETCH_C_WAIT, EXECUTE, WRITEBACK, REGISTER_WRITEBACK, and HALT cycles
## The end!

**Prometheus Lite ISA v1.0**

Designed for a compact, high frequency, 8 bit ASIC CPU.
