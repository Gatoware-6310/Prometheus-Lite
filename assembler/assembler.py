# Prometheus Lite assembler, made in python to make my life easy.
# Probably gonna rewrite in a faster language later?

import sys

data = bytearray()

def raise_error(msg):
    raise Exception(msg)

if len(sys.argv) < 3 or len(sys.argv) > 3:
    raise_error("Usage: python assembler.py filename.asm output.bin")

source = sys.argv[1]
output_file = sys.argv[2]

def immediate(integer):
    integer = int(integer)
    return int(integer) if (integer) <= 255 and int(integer) >= 0 else raise_error("Immediate cannot be higher than 255 or lower than 0")

def get_pair(pair):
    match pair.lower():
        case 'ab':
            return 0x00
        case 'cd':
            return 0x01
        case _:
            raise_error("Invalid register pair: " + pair)

def get_register(reg: str):
    match reg.lower():
        case 'a':
            return 0x00
        case 'b':
            return 0x01
        case 'c':
            return 0x02
        case 'd':
            return 0x03
        case _:
            raise_error("Invalid register: " + reg)

def movabcd(opcode, operand):
    data.append(opcode)
    data.append((int(operand, 0) >> 8) & 0x07) # Shift right 8 bits, AND with 0b111
    data.append(int(operand, 0) & 0xFF) # AND with 0b11111111

def assemble_instruction(instruction):
    split = instruction.replace(",", "").split()

    if len(split) < 3:
        for _ in range(3 - len(split)):
            split.append('')
    elif len(split) > 3:
        raise_error("Too many operands: " + instruction)
    
    opcode = split[0]
    operands = [split[1], split[2]]
    
    match opcode:
        case 'movi':
            data.append(0x00)
            data.append(get_register(operands[0]))
            data.append(immediate(operands[1]))
        case 'movr':
            data.append(0x01)
            data.append(get_register(operands[0]))
            data.append(get_register(operands[1]))
        case 'mova':
            movabcd(0x02, operands[0])
        case 'movb':
            movabcd(0x03, operands[0])
        case 'movc':
            movabcd(0x04, operands[0])
        case 'movd':
            movabcd(0x05, operands[0])
        case 'movfa':
            movabcd(0x06, operands[0]) # We can reuse this as operands are the same
        case 'movfb':
            movabcd(0x07, operands[0])
        case 'movfc':
            movabcd(0x08, operands[0])
        case 'movfd':
            movabcd(0x09, operands[0])
        case 'movp':
            data.append(0x0A)
            data.append(get_register(operands[0]))
            data.append(get_pair(operands[1]))
        case 'movfp':
            data.append(0x0B)
            data.append(get_pair(operands[0]))
            data.append(get_register(operands[1]))
        case 'add':
            data.append(0x10)
            data.append(get_register(operands[0]))
            data.append(get_register(operands[1]))
        case 'sub':
            data.append(0x12)
            data.append(get_register(operands[0]))
            data.append(get_register(operands[1]))
        case 'addi':
            data.append(0x17)
            data.append(get_register(operands[0]))
            data.append(immediate(operands[1]))
        case 'subi':
            data.append(0x18)
            data.append(get_register(operands[0]))
            data.append(immediate(operands[1]))
        case 'inc':
            data.append(0x17)
            data.append(get_register(operands[0]))
            data.append(1)
        case 'dec':
            data.append(0x18)
            data.append(get_register(operands[0]))
            data.append(1)
        case 'jmp':
            movabcd(0x30, operands[0]) # We can actually reuse this for jump because it's the same opcode/operand format
        case 'jz':
            movabcd(0x31, operands[0]) # We can actually reuse this for jump because it's the same opcode/operand format
        case 'cmp':
            data.append(0x16)
            data.append(get_register(operands[0]))
            data.append(get_register(operands[1]))
        case 'mul':
            data.append(0x19)
            data.append(get_register(operands[0]))
            data.append(get_register(operands[1]))
        case 'and':
            data.append(0x20)
            data.append(get_register(operands[0]))
            data.append(get_register(operands[1]))
        case 'or':
            data.append(0x21)
            data.append(get_register(operands[0]))
            data.append(get_register(operands[1]))
        case 'xor':
            data.append(0x22)
            data.append(get_register(operands[0]))
            data.append(get_register(operands[1]))
        case 'not':
            data.append(0x23)
            data.append(get_register(operands[0]))
            data.append(0x00)
        case 'shl':
            data.append(0x24)
            data.append(get_register(operands[0]))
            data.append(0x00)
        case 'shr':
            data.append(0x25)
            data.append(get_register(operands[0]))
            data.append(0x00)
        case 'nop':
            pass # TODO: Implement later, this is for testing single word instructions
        case _:
            raise_error("Illegal instruction encountered: " + opcode)
            return

with open(source, 'r', encoding='utf-8') as file:
    for instruction in file:
        assemble_instruction(instruction)

with open(output_file, 'wb') as binary: # Output binary data
    binary.write(data)

# Hex data for verilog
hex_string = " ".join(f"{b:02X}" for b in data) # Iterate through every byte in the byte array, make it a 2 digit hexadecimal string. Also add spaces after each.

with open(output_file + ".hex", 'w', encoding='utf-8') as hex_file: # Write it
    hex_file.write(hex_string)

print(f"Assembled {int(len(data) / 3)} instructions ({len(data)} bytes).")
print(f"OUTPUTS: {output_file}, {"hex_" + output_file}")
