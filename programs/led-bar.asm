movi a, 0
out a, 0x01
movi b, 20
movi c, 250
movi d, 250
subi d, 1
jnz 0x0f
subi c, 1
jnz 0x0c
subi b, 1
jnz 0x09
movi d, 248
cmp a, d
jz 0x00
shl a
addi a, 8
jmp 0x03
