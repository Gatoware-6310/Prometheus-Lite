# Prometheus Lite assembler, made in python to make my life easy.
# Probably gonna rewrite in a faster language later?

user_input = input()
data = bytearray()

def raise_error(msg):
    raise Exception(msg)

def get_register(reg: String):
    match reg.lower():
        case 'a':
            return 0x00
        case 'b':
            return 0x01
        case 'c':
            return 0x02
        case 'd':
            return 0x03

def assemble_instruction(instruction):
    opcode = instruction.replace(",", "").split()[0]
    operands = [instruction.replace(",", "").split()[1], instruction.replace(",", "").split()[2]]
    
    match opcode:
        case 'movi':
            data.append(0x00)
            data.append(get_register(operands[0]))
            data.append(int(operands[1]) if (int(operands[1]) <= 255 and int(operands[1]) > 0) else raise_error("Immediate cannot be higher than 255 or lower than 0"))
        case _:
            raise_error("Illegal instruction encountered: " + opcode)
            return

assemble_instruction(user_input)
for b in data:
    print(b)