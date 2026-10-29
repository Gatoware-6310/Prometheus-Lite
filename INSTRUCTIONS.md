
# Instructions

| Opcode | Instruction | Implemented |
|---|---|---|
| `0x00` | `movi [register], [immediate]` | [x] |
| `0x01` | `movr [destination], [source]` | [x] |
| `0x02` | `mova [address]` | [x] |
| `0x03` | `movb [address]` | [x] |
| `0x04` | `movc [address]` | [x] |
| `0x05` | `movd [address]` | [x] |
| `0x06` | `movfa [address]` | [x] |
| `0x07` | `movfb [address]` | [x] |
| `0x08` | `movfc [address]` | [x] |
| `0x09` | `movfd [address]` | [x] |
| `0x0A` | `movp [destination], [pair]` | [x] |
| `0x0B` | `movfp [pair], [source]` | [x] |
| `0x10` | `add [destination], [source]` | [x] |
| `0x11` | `adc [destination], [source]` | [ ] |
| `0x12` | `sub [destination], [source]` | [x] |
| `0x13` | `sbc [destination], [source]` | [ ] |
| `0x14` | `inc (ASSEMBLER MACRO) [register]` | [x] |
| `0x15` | `dec (ASSEMBLER MACRO) [register]` | [x] |
| `0x16` | `cmp [destination], [source]` | [x] |
| `0x17` | `addi [register], [immediate]` | [x] |
| `0x18` | `subi [register], [immediate]` | [x] |
| `0x19` | `mul [destination], [source]` | [x] |
| `0x20` | `and [destination], [source]` | [x] |
| `0x21` | `or [destination], [source]` | [x] |
| `0x22` | `xor [destination], [source]` | [x] |
| `0x23` | `not [register]` | [x] |
| `0x24` | `shl [register]` | [x] |
| `0x25` | `shr [register]` | [x] |
| `0x30` | `jmp [address]` | [x] |
| `0x31` | `jz [address]` | [x] |
| `0x32` | `jnz [address]` | [x] |
| `0x33` | `jc [address]` | [ ] |
| `0x34` | `jnc [address]` | [ ] |
| `0x35` | `jmpp` | [x] |
| `0x40` | `push [register]` | [x] |
| `0x41` | `pop [register]` | [x] |
| `0x42` | `call [address]` | [ ] |
| `0x43` | `ret` | [ ] |
| `0x50` | `clc` | [ ] |
| `0x51` | `sec` | [ ] |
| `0x52` | `nop` | [x] |
| `0x53` | `hlt` | [x] |