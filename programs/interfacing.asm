movi d, 1
movi c, 0
out c, 0x01
in a, 0x00
movi b, 0
cmp a, b
jz 9
movi b, 112
cmp a, b
jz 72
movi b, 118
cmp a, b
jz 78
movi b, 99
cmp a, b
jz 84
movi b, 110
cmp a, b
jz 90
movi b, 114
cmp a, b
jz 111
movi c, 127
jmp 120
movi c, 80
jmp 120
movi c, 16
jmp 120
movr c, d
jmp 120
inc d
movi b, 0
cmp d, b
jnz 105
movi d, 1
movr c, d
jmp 120
movi d, 1
movi c, 82
jmp 120
out c, 0x01
in a, 0x00
movi b, 0
cmp a, b
jnz 123
movi c, 0
out c, 0x01
jmp 9
