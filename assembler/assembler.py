# Prometheus Lite assembler, made in python to make my life easy.
# Probably gonna rewrite in a faster language later?

user_input = input()
data = bytearray()

def raise_error(msg):
    raise Exception(msg)

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
            data.append(int(operands[1]) if (int(operands[1]) <= 255 and int(operands[1]) >= 0) else raise_error("Immediate cannot be higher than 255 or lower than 0"))
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
        case 'nop':
            pass # TODO: Implement later, this is for testing single word instructions
        case _:
            raise_error("Illegal instruction encountered: " + opcode)
            return

assemble_instruction(user_input)
for b in data:
    print(b)