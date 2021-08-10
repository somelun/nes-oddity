const std = @import("std");
const AutoHashMap = @import("std").AutoHashMap;

pub const AddressingMode = enum {
    Implied,
    Accumulator,
    Immediate,
    ZeroPage,
    ZeroPageX,
    ZeroPageY,
    Relative,
    Absolute,
    AbsoluteX,
    AbsoluteY,
    Indirect,
    IndirectX,
    IndirectY,
};

pub const Opcode = struct {
    name: []const u8, // TODO: replace with [3]u8 maybe?
    addressing_mode: AddressingMode,
    length: u8,
    cycles: u8,

    pub fn init(name: []const u8, addressing_mode: AddressingMode, length: u8, cycles: u8) Opcode {
        return Opcode{
            .name = name,
            .addressing_mode = addressing_mode,
            .length = length,
            .cycles = cycles,
        };
    }
};

// https://www.masswerk.at/6502/6502_instruction_set.html
pub fn generateOcpodes() [256]Opcode {
    var opcodes: [256]Opcode = undefined;

    // ADC: Add Memory to Accumulator with Carry
    opcodes[0x69] = Opcode.init("ADC", AddressingMode.Immediate, 2, 2);
    opcodes[0x65] = Opcode.init("ADC", AddressingMode.ZeroPage, 2, 3);
    opcodes[0x75] = Opcode.init("ADC", AddressingMode.ZeroPageX, 2, 4);
    opcodes[0x6D] = Opcode.init("ADC", AddressingMode.Absolute, 3, 4);
    opcodes[0x7D] = Opcode.init("ADC", AddressingMode.AbsoluteX, 3, 4);
    opcodes[0x79] = Opcode.init("ADC", AddressingMode.AbsoluteY, 3, 4);
    opcodes[0x61] = Opcode.init("ADC", AddressingMode.IndirectX, 2, 6);
    opcodes[0x71] = Opcode.init("ADC", AddressingMode.IndirectY, 2, 5);

    // AND: AND Memory with Accumulator
    opcodes[0x29] = Opcode.init("AND", AddressingMode.Immediate, 2, 2);
    opcodes[0x25] = Opcode.init("AND", AddressingMode.ZeroPage, 2, 3);
    opcodes[0x35] = Opcode.init("AND", AddressingMode.ZeroPageX, 2, 4);
    opcodes[0x2D] = Opcode.init("AND", AddressingMode.Absolute, 3, 4);
    opcodes[0x3D] = Opcode.init("AND", AddressingMode.AbsoluteX, 3, 4);
    opcodes[0x39] = Opcode.init("AND", AddressingMode.AbsoluteY, 3, 2);
    opcodes[0x21] = Opcode.init("AND", AddressingMode.IndirectX, 2, 6);
    opcodes[0x31] = Opcode.init("AND", AddressingMode.IndirectY, 2, 5);

    // ASL: Shift Left One Bit (Memory or Accumulator)
    opcodes[0x0A] = Opcode.init("ASL", AddressingMode.Accumulator, 1, 2);
    opcodes[0x06] = Opcode.init("ASL", AddressingMode.ZeroPage, 2, 5);
    opcodes[0x16] = Opcode.init("ASL", AddressingMode.ZeroPageX, 2, 6);
    opcodes[0x0E] = Opcode.init("ASL", AddressingMode.Absolute, 3, 6);
    opcodes[0x1E] = Opcode.init("ASL", AddressingMode.AbsoluteX, 3, 7);

    // BCC: Branch on Carry Clear
    opcodes[0x90] = Opcode.init("BCC", AddressingMode.Relative, 2, 2);

    // BCS: Branch on Carry Set
    opcodes[0xB0] = Opcode.init("BCS", AddressingMode.Relative, 2, 2);

    // BEQ: Branch on Result Zero
    opcodes[0xF0] = Opcode.init("BEQ", AddressingMode.Relative, 2, 2);

    // BIT: Test Bits in Memory with Accumulator
    opcodes[0x24] = Opcode.init("BIT", AddressingMode.ZeroPage, 2, 3);
    opcodes[0x2C] = Opcode.init("BIT", AddressingMode.Absolute, 3, 4);

    // BMI: Branch on Result Minus
    opcodes[0x30] = Opcode.init("BMI", AddressingMode.Relative, 2, 2);

    // BNE: Branch on Result not Zero
    opcodes[0xD0] = Opcode.init("BNE", AddressingMode.Relative, 2, 2);

    // BPL: Branch on Result Plus
    opcodes[0x10] = Opcode.init("BPL", AddressingMode.Relative, 2, 2);

    // BRK: Force Break
    opcodes[0x00] = Opcode.init("BRK", AddressingMode.Implied, 1, 7);

    // BVC: Branch on Overflow Clear
    opcodes[0x50] = Opcode.init("BVC", AddressingMode.Relative, 2, 2);

    // BVS: Branch on Overflow Set
    opcodes[0x70] = Opcode.init("BVS", AddressingMode.Relative, 2, 2);

    // CLC: Clear Carry Flag
    opcodes[0x18] = Opcode.init("CLC", AddressingMode.Implied, 1, 2);

    // CLD: Clear Decimal Flag
    opcodes[0xD8] = Opcode.init("CLD", AddressingMode.Implied, 1, 2);

    // CLI: Clear Interrupt Disable Bit
    opcodes[0x58] = Opcode.init("CLI", AddressingMode.Implied, 1, 2);

    // CLV: Clear Overlfow Bit
    opcodes[0xB8] = Opcode.init("CLV", AddressingMode.Implied, 1, 2);

    // CMP: Compare Memory with Accumulator
    opcodes[0xC9] = Opcode.init("CMP", AddressingMode.Immediate, 2, 2);
    opcodes[0xC5] = Opcode.init("CMP", AddressingMode.ZeroPage, 2, 3);
    opcodes[0xD5] = Opcode.init("CMP", AddressingMode.ZeroPageX, 2, 4);
    opcodes[0xCD] = Opcode.init("CMP", AddressingMode.Absolute, 3, 4);
    opcodes[0xDD] = Opcode.init("CMP", AddressingMode.AbsoluteX, 3, 4);
    opcodes[0xD9] = Opcode.init("CMP", AddressingMode.AbsoluteY, 3, 4);
    opcodes[0xC1] = Opcode.init("CMP", AddressingMode.IndirectX, 2, 6);
    opcodes[0xD1] = Opcode.init("CMP", AddressingMode.IndirectY, 2, 5);

    // CPX: Compare Memory and Register X
    opcodes[0xE0] = Opcode.init("CPX", AddressingMode.Immediate, 2, 2);
    opcodes[0xE4] = Opcode.init("CPX", AddressingMode.ZeroPage, 2, 3);
    opcodes[0xEC] = Opcode.init("CPX", AddressingMode.Absolute, 3, 4);

    // CPY: Compare Memory and Register Y
    opcodes[0xC0] = Opcode.init("CPY", AddressingMode.Immediate, 2, 2);
    opcodes[0xC4] = Opcode.init("CPY", AddressingMode.ZeroPage, 2, 3);
    opcodes[0xCC] = Opcode.init("CPY", AddressingMode.Absolute, 3, 4);

    // DEC: Decrement Memory by One
    opcodes[0xC6] = Opcode.init("DEC", AddressingMode.ZeroPage, 2, 5);
    opcodes[0xD6] = Opcode.init("DEC", AddressingMode.ZeroPageX, 2, 6);
    opcodes[0xCE] = Opcode.init("DEC", AddressingMode.Absolute, 3, 6);
    opcodes[0xDE] = Opcode.init("DEC", AddressingMode.AbsoluteX, 3, 7);

    // DEX: Decrement Register X by One
    opcodes[0xCA] = Opcode.init("DEX", AddressingMode.Implied, 1, 2);

    // DEY: Decrement Register Y by One
    opcodes[0x88] = Opcode.init("DEY", AddressingMode.Implied, 1, 2);

    // EOR: Exclusive-OR Memory with Accumulator
    opcodes[0x49] = Opcode.init("EOR", AddressingMode.Immediate, 2, 2);
    opcodes[0x45] = Opcode.init("EOR", AddressingMode.ZeroPage, 2, 3);
    opcodes[0x55] = Opcode.init("EOR", AddressingMode.ZeroPageX, 2, 4);
    opcodes[0x4D] = Opcode.init("EOR", AddressingMode.Absolute, 3, 4);
    opcodes[0x5D] = Opcode.init("EOR", AddressingMode.AbsoluteX, 3, 4);
    opcodes[0x59] = Opcode.init("EOR", AddressingMode.AbsoluteY, 3, 4);
    opcodes[0x41] = Opcode.init("EOR", AddressingMode.IndirectX, 2, 6);
    opcodes[0x51] = Opcode.init("EOR", AddressingMode.IndirectY, 2, 5);

    // INC: Increment Memory by One
    opcodes[0xE6] = Opcode.init("INC", AddressingMode.ZeroPage, 2, 5);
    opcodes[0xF6] = Opcode.init("INC", AddressingMode.ZeroPageX, 2, 6);
    opcodes[0xEE] = Opcode.init("INC", AddressingMode.Absolute, 3, 6);
    opcodes[0xFE] = Opcode.init("INC", AddressingMode.AbsoluteX, 3, 7);

    // INX: Increment Register X by One
    opcodes[0xE8] = Opcode.init("INX", AddressingMode.Implied, 1, 2);

    // INY: Increment Register Y by One
    opcodes[0xC8] = Opcode.init("INY", AddressingMode.Implied, 1, 2);

    // JMP: Jump to New Location
    opcodes[0x4C] = Opcode.init("JMP", AddressingMode.Absolute, 3, 3);
    opcodes[0x6C] = Opcode.init("JMP", AddressingMode.Indirect, 3, 5);

    // JSR: Jump to New Location Saving Retutn Address
    opcodes[0x20] = Opcode.init("JSR", AddressingMode.Absolute, 3, 6);

    // LDA: Load Accumulator with Memory
    opcodes[0xA9] = Opcode.init("LDA", AddressingMode.Immediate, 2, 2);
    opcodes[0xA5] = Opcode.init("LDA", AddressingMode.ZeroPage, 2, 3);
    opcodes[0xB5] = Opcode.init("LDA", AddressingMode.ZeroPageX, 2, 4);
    opcodes[0xAD] = Opcode.init("LDA", AddressingMode.Absolute, 3, 4);
    opcodes[0xBD] = Opcode.init("LDA", AddressingMode.AbsoluteX, 3, 4);
    opcodes[0xB9] = Opcode.init("LDA", AddressingMode.AbsoluteY, 3, 4);
    opcodes[0xA1] = Opcode.init("LDA", AddressingMode.IndirectX, 2, 6);
    opcodes[0xB1] = Opcode.init("LDA", AddressingMode.IndirectY, 2, 5);

    // LDX: Load Register X with Memory
    opcodes[0xA2] = Opcode.init("LDX", AddressingMode.Immediate, 2, 2);
    opcodes[0xA6] = Opcode.init("LDX", AddressingMode.ZeroPage, 2, 3);
    opcodes[0xB6] = Opcode.init("LDX", AddressingMode.ZeroPageY, 2, 4);
    opcodes[0xAE] = Opcode.init("LDX", AddressingMode.Absolute, 3, 4);
    opcodes[0xBE] = Opcode.init("LDX", AddressingMode.AbsoluteY, 3, 4);

    // LDY: Load Register Y with Memory
    opcodes[0xA0] = Opcode.init("LDY", AddressingMode.Immediate, 2, 2);
    opcodes[0xA4] = Opcode.init("LDY", AddressingMode.ZeroPage, 2, 3);
    opcodes[0xB4] = Opcode.init("LDY", AddressingMode.ZeroPageX, 2, 4);
    opcodes[0xAC] = Opcode.init("LDY", AddressingMode.Absolute, 3, 4);
    opcodes[0xBC] = Opcode.init("LDY", AddressingMode.AbsoluteX, 3, 4);

    // LSR: Shift Ont Bit Right (Memory or Accumulator)
    opcodes[0x4A] = Opcode.init("LSR", AddressingMode.Accumulator, 1, 2);
    opcodes[0x46] = Opcode.init("LSR", AddressingMode.ZeroPage, 2, 5);
    opcodes[0x56] = Opcode.init("LSR", AddressingMode.ZeroPageX, 2, 6);
    opcodes[0x4E] = Opcode.init("LSR", AddressingMode.Absolute, 3, 6);
    opcodes[0x5E] = Opcode.init("LSR", AddressingMode.AbsoluteX, 3, 7);

    // NOP: No Operation
    opcodes[0xEA] = Opcode.init("NOP", AddressingMode.Implied, 1, 2);

    // ORA: OR Memory with Accumulator
    opcodes[0x09] = Opcode.init("ORA", AddressingMode.Immediate, 2, 2);
    opcodes[0x05] = Opcode.init("ORA", AddressingMode.ZeroPage, 2, 3);
    opcodes[0x15] = Opcode.init("ORA", AddressingMode.ZeroPageX, 2, 4);
    opcodes[0x0D] = Opcode.init("ORA", AddressingMode.Absolute, 3, 4);
    opcodes[0x1D] = Opcode.init("ORA", AddressingMode.AbsoluteX, 3, 4);
    opcodes[0x19] = Opcode.init("ORA", AddressingMode.AbsoluteY, 3, 4);
    opcodes[0x01] = Opcode.init("ORA", AddressingMode.IndirectX, 2, 6);
    opcodes[0x11] = Opcode.init("ORA", AddressingMode.IndirectY, 2, 5);

    // PHA: Push Accumulator on Stack
    opcodes[0x48] = Opcode.init("PHA", AddressingMode.Implied, 1, 3);

    // PHP: Push Processor Status on Stack
    opcodes[0x08] = Opcode.init("PHP", AddressingMode.Implied, 1, 3);

    // PLA: Pull Accumulator from Stack
    opcodes[0x68] = Opcode.init("PLA", AddressingMode.Implied, 1, 4);

    // PLP: Pull Processor Status from Stack
    opcodes[0x28] = Opcode.init("PLP", AddressingMode.Implied, 1, 4);

    // ROL: Rotate Ont Bit Left (Memory or Accumulator)
    opcodes[0x2A] = Opcode.init("ROL", AddressingMode.Accumulator, 1, 2);
    opcodes[0x26] = Opcode.init("ROL", AddressingMode.ZeroPage, 2, 5);
    opcodes[0x36] = Opcode.init("ROL", AddressingMode.ZeroPageX, 2, 6);
    opcodes[0x2E] = Opcode.init("ROL", AddressingMode.Absolute, 3, 6);
    opcodes[0x3E] = Opcode.init("ROL", AddressingMode.AbsoluteX, 3, 7);

    // ROR: Rotate Ont Bit Right (Memory or Accumulator)
    opcodes[0x6A] = Opcode.init("ROR", AddressingMode.Accumulator, 1, 2);
    opcodes[0x66] = Opcode.init("ROR", AddressingMode.ZeroPage, 2, 5);
    opcodes[0x76] = Opcode.init("ROR", AddressingMode.ZeroPageX, 2, 6);
    opcodes[0x6E] = Opcode.init("ROR", AddressingMode.Absolute, 3, 6);
    opcodes[0x7E] = Opcode.init("ROR", AddressingMode.AbsoluteX, 3, 7);

    // RTI: Return from Interrupt
    opcodes[0x40] = Opcode.init("RTI", AddressingMode.Implied, 1, 6);

    // RTS: Return from Subroutine
    opcodes[0x60] = Opcode.init("RTS", AddressingMode.Implied, 1, 6);

    // SBC: Substruct Memory from Accumulator with Borrow
    opcodes[0xE9] = Opcode.init("SBC", AddressingMode.Immediate, 2, 2);
    opcodes[0xE5] = Opcode.init("SBC", AddressingMode.ZeroPage, 2, 3);
    opcodes[0xF5] = Opcode.init("SBC", AddressingMode.ZeroPageX, 2, 4);
    opcodes[0xED] = Opcode.init("SBC", AddressingMode.Absolute, 3, 4);
    opcodes[0xFD] = Opcode.init("SBC", AddressingMode.AbsoluteX, 3, 4);
    opcodes[0xF9] = Opcode.init("SBC", AddressingMode.AbsoluteY, 3, 4);
    opcodes[0xE1] = Opcode.init("SBC", AddressingMode.IndirectX, 2, 6);
    opcodes[0xF1] = Opcode.init("SBC", AddressingMode.IndirectY, 2, 5);

    // SEC: Set Carry Flag
    opcodes[0x38] = Opcode.init("SEC", AddressingMode.Implied, 1, 2);

    // SED: Set Deciamal Flag
    opcodes[0xF8] = Opcode.init("SED", AddressingMode.Implied, 1, 2);

    // SEI: Set Interrupt Disable Flag
    opcodes[0x78] = Opcode.init("SEI", AddressingMode.Implied, 1, 2);

    // STA: Store Accumulator in Memory
    opcodes[0x85] = Opcode.init("STA", AddressingMode.ZeroPage, 2, 3);
    opcodes[0x95] = Opcode.init("STA", AddressingMode.ZeroPageX, 2, 4);
    opcodes[0x8D] = Opcode.init("STA", AddressingMode.Absolute, 3, 4);
    opcodes[0x9D] = Opcode.init("STA", AddressingMode.AbsoluteX, 3, 5);
    opcodes[0x99] = Opcode.init("STA", AddressingMode.AbsoluteY, 3, 5);
    opcodes[0x81] = Opcode.init("STA", AddressingMode.IndirectX, 2, 6);
    opcodes[0x91] = Opcode.init("STA", AddressingMode.IndirectY, 2, 6);

    // STX: Store Register X in Memory
    opcodes[0x86] = Opcode.init("STX", AddressingMode.ZeroPage, 2, 3);
    opcodes[0x96] = Opcode.init("STX", AddressingMode.ZeroPageY, 2, 4);
    opcodes[0x8E] = Opcode.init("STX", AddressingMode.Absolute, 3, 4);

    // STY: Store Register Y in Memory
    opcodes[0x84] = Opcode.init("STY", AddressingMode.ZeroPage, 2, 3);
    opcodes[0x94] = Opcode.init("STY", AddressingMode.ZeroPageX, 2, 4);
    opcodes[0x8C] = Opcode.init("STY", AddressingMode.Absolute, 3, 4);

    // TAX: Transfer Accumulator to Register X
    opcodes[0xAA] = Opcode.init("TAX", AddressingMode.Implied, 1, 2);

    // TAY: Transfer Accumulator to Register Y
    opcodes[0xA8] = Opcode.init("TAY", AddressingMode.Implied, 1, 2);

    // TSX: Transfer Stack Pointer to Register X
    opcodes[0xBA] = Opcode.init("TSX", AddressingMode.Implied, 1, 2);

    // TXA: Transfer Register X to Accumulator
    opcodes[0x8A] = Opcode.init("TXA", AddressingMode.Implied, 1, 2);

    // TXS: Transfer Register X to Stack Register
    opcodes[0x9A] = Opcode.init("TXS", AddressingMode.Implied, 1, 2);

    // TYA: Transfer Register Y to Accumulator
    opcodes[0x98] = Opcode.init("TYA", AddressingMode.Implied, 1, 2);

    // UNOFFICIAL OPCODES
    // https://www.nesdev.com/undocumented_opcodes.txt

    // *NOP: No Operation
    opcodes[0x04] = Opcode.init("*NOP", AddressingMode.ZeroPage, 2, 3);
    opcodes[0x14] = Opcode.init("*NOP", AddressingMode.ZeroPageX, 2, 4);
    opcodes[0x34] = Opcode.init("*NOP", AddressingMode.ZeroPageX, 2, 4);
    opcodes[0x44] = Opcode.init("*NOP", AddressingMode.ZeroPage, 2, 3);
    opcodes[0x54] = Opcode.init("*NOP", AddressingMode.ZeroPageX, 2, 4);
    opcodes[0x64] = Opcode.init("*NOP", AddressingMode.ZeroPage, 2, 3);
    opcodes[0x74] = Opcode.init("*NOP", AddressingMode.ZeroPageX, 2, 4);
    opcodes[0x80] = Opcode.init("*NOP", AddressingMode.Immediate, 2, 2);
    opcodes[0x82] = Opcode.init("*NOP", AddressingMode.Immediate, 2, 2);
    opcodes[0x89] = Opcode.init("*NOP", AddressingMode.Immediate, 2, 2);
    opcodes[0xC2] = Opcode.init("*NOP", AddressingMode.Immediate, 2, 2);
    opcodes[0xD4] = Opcode.init("*NOP", AddressingMode.ZeroPageX, 2, 4);
    opcodes[0xE2] = Opcode.init("*NOP", AddressingMode.Immediate, 2, 2);
    opcodes[0xF4] = Opcode.init("*NOP", AddressingMode.ZeroPageX, 2, 4);

    opcodes[0x0C] = Opcode.init("*NOP", AddressingMode.Absolute, 3, 4);
    opcodes[0x1C] = Opcode.init("*NOP", AddressingMode.AbsoluteX, 3, 4);
    opcodes[0x3C] = Opcode.init("*NOP", AddressingMode.AbsoluteX, 3, 4);
    opcodes[0x5C] = Opcode.init("*NOP", AddressingMode.AbsoluteX, 3, 4);
    opcodes[0x7C] = Opcode.init("*NOP", AddressingMode.AbsoluteX, 3, 4);
    opcodes[0xDC] = Opcode.init("*NOP", AddressingMode.AbsoluteX, 3, 4);
    opcodes[0xFC] = Opcode.init("*NOP", AddressingMode.AbsoluteX, 3, 4);

    opcodes[0x1A] = Opcode.init("*NOP", AddressingMode.Implied, 1, 2);
    opcodes[0x3A] = Opcode.init("*NOP", AddressingMode.Implied, 1, 2);
    opcodes[0x5A] = Opcode.init("*NOP", AddressingMode.Implied, 1, 2);
    opcodes[0x7A] = Opcode.init("*NOP", AddressingMode.Implied, 1, 2);
    opcodes[0xDA] = Opcode.init("*NOP", AddressingMode.Implied, 1, 2);
    opcodes[0xFA] = Opcode.init("*NOP", AddressingMode.Implied, 1, 2);

    // *LAX: Load to A and X
    opcodes[0xA7] = Opcode.init("*LAX", AddressingMode.ZeroPage, 2, 3);
    opcodes[0xB7] = Opcode.init("*LAX", AddressingMode.ZeroPageY, 2, 4);
    opcodes[0xAF] = Opcode.init("*LAX", AddressingMode.Absolute, 3, 4);
    opcodes[0xBF] = Opcode.init("*LAX", AddressingMode.AbsoluteY, 3, 4);
    opcodes[0xA3] = Opcode.init("*LAX", AddressingMode.IndirectX, 2, 6);
    opcodes[0xB3] = Opcode.init("*LAX", AddressingMode.IndirectY, 2, 5);

    // *SAX
    opcodes[0x87] = Opcode.init("*SAX", AddressingMode.ZeroPage, 2, 3);
    opcodes[0x97] = Opcode.init("*SAX", AddressingMode.ZeroPageY, 2, 4);
    opcodes[0x83] = Opcode.init("*SAX", AddressingMode.IndirectX, 2, 6);
    opcodes[0x8F] = Opcode.init("*SAX", AddressingMode.Absolute, 3, 4);

    // *SBC
    opcodes[0xEB] = Opcode.init("*SBC", AddressingMode.Immediate, 2, 2);

    // *DCP
    opcodes[0xC7] = Opcode.init("*DCP", AddressingMode.ZeroPage, 2, 5);
    opcodes[0xD7] = Opcode.init("*DCP", AddressingMode.ZeroPageX, 2, 6);
    opcodes[0xCF] = Opcode.init("*DCP", AddressingMode.Absolute, 3, 6);
    opcodes[0xDF] = Opcode.init("*DCP", AddressingMode.AbsoluteX, 3, 7);
    opcodes[0xDB] = Opcode.init("*DCP", AddressingMode.AbsoluteY, 3, 7);
    opcodes[0xC3] = Opcode.init("*DCP", AddressingMode.IndirectX, 2, 8);
    opcodes[0xD3] = Opcode.init("*DCP`", AddressingMode.IndirectY, 2, 8);

    return opcodes;
}
