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
pub fn generateOpcodes() AutoHashMap(u8, Opcode) {
    var opcodes = AutoHashMap(u8, Opcode).init(std.heap.page_allocator);

    // ADC: Add Memory to Accumulator with Carry
    opcodes.put(0x69, Opcode.init("ADC", AddressingMode.Immediate, 2, 2)) catch unreachable;
    opcodes.put(0x65, Opcode.init("ADC", AddressingMode.ZeroPage, 2, 3)) catch unreachable;
    opcodes.put(0x75, Opcode.init("ADC", AddressingMode.ZeroPageX, 2, 4)) catch unreachable;
    opcodes.put(0x6D, Opcode.init("ADC", AddressingMode.Absolute, 3, 4)) catch unreachable;
    opcodes.put(0x7D, Opcode.init("ADC", AddressingMode.AbsoluteX, 3, 4)) catch unreachable;
    opcodes.put(0x79, Opcode.init("ADC", AddressingMode.AbsoluteY, 3, 4)) catch unreachable;
    opcodes.put(0x61, Opcode.init("ADC", AddressingMode.IndirectX, 2, 6)) catch unreachable;
    opcodes.put(0x71, Opcode.init("ADC", AddressingMode.IndirectY, 2, 5)) catch unreachable;

    // AND: AND Memory with Accumulator
    opcodes.put(0x29, Opcode.init("AND", AddressingMode.Immediate, 2, 2)) catch unreachable;
    opcodes.put(0x25, Opcode.init("AND", AddressingMode.ZeroPage, 2, 3)) catch unreachable;
    opcodes.put(0x35, Opcode.init("AND", AddressingMode.ZeroPageX, 2, 4)) catch unreachable;
    opcodes.put(0x2D, Opcode.init("AND", AddressingMode.Absolute, 3, 4)) catch unreachable;
    opcodes.put(0x3D, Opcode.init("AND", AddressingMode.AbsoluteX, 3, 4)) catch unreachable;
    opcodes.put(0x39, Opcode.init("AND", AddressingMode.AbsoluteY, 3, 2)) catch unreachable;
    opcodes.put(0x21, Opcode.init("AND", AddressingMode.IndirectX, 2, 6)) catch unreachable;
    opcodes.put(0x31, Opcode.init("AND", AddressingMode.IndirectY, 2, 5)) catch unreachable;

    // ASL: Shift Left One Bit (Memory or Accumulator)
    opcodes.put(0x0A, Opcode.init("ASL", AddressingMode.Accumulator, 1, 2)) catch unreachable;
    opcodes.put(0x06, Opcode.init("ASL", AddressingMode.ZeroPage, 2, 5)) catch unreachable;
    opcodes.put(0x16, Opcode.init("ASL", AddressingMode.ZeroPageX, 2, 6)) catch unreachable;
    opcodes.put(0x0E, Opcode.init("ASL", AddressingMode.Absolute, 3, 6)) catch unreachable;
    opcodes.put(0x1E, Opcode.init("ASL", AddressingMode.AbsoluteX, 3, 7)) catch unreachable;

    // BCC: Branch on Carry Clear
    opcodes.put(0x90, Opcode.init("BCC", AddressingMode.Relative, 2, 2)) catch unreachable;

    // BCS: Branch on Carry Set
    opcodes.put(0xB0, Opcode.init("BCS", AddressingMode.Relative, 2, 2)) catch unreachable;

    // BEQ: Branch on Result Zero
    opcodes.put(0xF0, Opcode.init("BEQ", AddressingMode.Relative, 2, 2)) catch unreachable;

    // BIT: Test Bits in Memory with Accumulator
    opcodes.put(0x24, Opcode.init("BIT", AddressingMode.ZeroPage, 2, 3)) catch unreachable;
    opcodes.put(0x2C, Opcode.init("BIT", AddressingMode.Absolute, 3, 4)) catch unreachable;

    // BMI: Branch on Result Minus
    opcodes.put(0x30, Opcode.init("BMI", AddressingMode.Relative, 2, 2)) catch unreachable;

    // BNE: Branch on Result not Zero
    opcodes.put(0xD0, Opcode.init("BNE", AddressingMode.Relative, 2, 2)) catch unreachable;

    // BPL: Branch on Result Plus
    opcodes.put(0x10, Opcode.init("BPL", AddressingMode.Relative, 2, 2)) catch unreachable;

    // BRK: Force Break
    opcodes.put(0x00, Opcode.init("BRK", AddressingMode.Implied, 1, 7)) catch unreachable;

    // BVC: Branch on Overflow Clear
    opcodes.put(0x50, Opcode.init("BVC", AddressingMode.Relative, 2, 2)) catch unreachable;

    // BVS: Branch on Overflow Set
    opcodes.put(0x70, Opcode.init("BVS", AddressingMode.Relative, 2, 2)) catch unreachable;

    // CLC: Clear Carry Flag
    opcodes.put(0x18, Opcode.init("CLC", AddressingMode.Implied, 1, 2)) catch unreachable;

    // CLD: Clear Decimal Flag
    opcodes.put(0xD8, Opcode.init("CLD", AddressingMode.Implied, 1, 2)) catch unreachable;

    // CLI: Clear Interrupt Disable Bit
    opcodes.put(0x58, Opcode.init("CLI", AddressingMode.Implied, 1, 2)) catch unreachable;

    // CLV: Clear Overlfow Bit
    opcodes.put(0xB8, Opcode.init("CLV", AddressingMode.Implied, 1, 2)) catch unreachable;

    // CMP: Compare Memory with Accumulator
    opcodes.put(0xC9, Opcode.init("CMP", AddressingMode.Immediate, 2, 2)) catch unreachable;
    opcodes.put(0xC5, Opcode.init("CMP", AddressingMode.ZeroPage, 2, 3)) catch unreachable;
    opcodes.put(0xD5, Opcode.init("CMP", AddressingMode.ZeroPageX, 2, 4)) catch unreachable;
    opcodes.put(0xCD, Opcode.init("CMP", AddressingMode.Absolute, 3, 4)) catch unreachable;
    opcodes.put(0xDD, Opcode.init("CMP", AddressingMode.AbsoluteX, 3, 4)) catch unreachable;
    opcodes.put(0xD9, Opcode.init("CMP", AddressingMode.AbsoluteY, 3, 4)) catch unreachable;
    opcodes.put(0xC1, Opcode.init("CMP", AddressingMode.IndirectX, 2, 6)) catch unreachable;
    opcodes.put(0xD1, Opcode.init("CMP", AddressingMode.IndirectY, 2, 5)) catch unreachable;

    // CPX: Compare Memory and Register X
    opcodes.put(0xE0, Opcode.init("CPX", AddressingMode.Immediate, 2, 2)) catch unreachable;
    opcodes.put(0xE4, Opcode.init("CPX", AddressingMode.ZeroPage, 2, 3)) catch unreachable;
    opcodes.put(0xEC, Opcode.init("CPX", AddressingMode.Absolute, 3, 4)) catch unreachable;

    // CPY: Compare Memory and Register Y
    opcodes.put(0xC0, Opcode.init("CPY", AddressingMode.Immediate, 2, 2)) catch unreachable;
    opcodes.put(0xC4, Opcode.init("CPY", AddressingMode.ZeroPage, 2, 3)) catch unreachable;
    opcodes.put(0xCC, Opcode.init("CPY", AddressingMode.Absolute, 3, 4)) catch unreachable;

    // DEC: Decrement Memory by One
    opcodes.put(0xC6, Opcode.init("DEC", AddressingMode.ZeroPage, 2, 5)) catch unreachable;
    opcodes.put(0xD6, Opcode.init("DEC", AddressingMode.ZeroPageX, 2, 6)) catch unreachable;
    opcodes.put(0xCE, Opcode.init("DEC", AddressingMode.Absolute, 3, 6)) catch unreachable;
    opcodes.put(0xDE, Opcode.init("DEC", AddressingMode.AbsoluteX, 3, 7)) catch unreachable;

    // DEX: Decrement Register X by One
    opcodes.put(0xCA, Opcode.init("DEX", AddressingMode.Implied, 1, 2)) catch unreachable;

    // DEY: Decrement Register Y by One
    opcodes.put(0x88, Opcode.init("DEY", AddressingMode.Implied, 1, 2)) catch unreachable;

    // EOR: Exclusive-OR Memory with Accumulator
    opcodes.put(0x49, Opcode.init("EOR", AddressingMode.Immediate, 2, 2)) catch unreachable;
    opcodes.put(0x45, Opcode.init("EOR", AddressingMode.ZeroPage, 2, 3)) catch unreachable;
    opcodes.put(0x55, Opcode.init("EOR", AddressingMode.ZeroPageX, 2, 4)) catch unreachable;
    opcodes.put(0x4D, Opcode.init("EOR", AddressingMode.Absolute, 3, 4)) catch unreachable;
    opcodes.put(0x5D, Opcode.init("EOR", AddressingMode.AbsoluteX, 3, 4)) catch unreachable;
    opcodes.put(0x59, Opcode.init("EOR", AddressingMode.AbsoluteY, 3, 4)) catch unreachable;
    opcodes.put(0x41, Opcode.init("EOR", AddressingMode.IndirectX, 2, 6)) catch unreachable;
    opcodes.put(0x51, Opcode.init("EOR", AddressingMode.IndirectY, 2, 5)) catch unreachable;

    // INC: Increment Memory by One
    opcodes.put(0xE6, Opcode.init("INC", AddressingMode.ZeroPage, 2, 5)) catch unreachable;
    opcodes.put(0xF6, Opcode.init("INC", AddressingMode.ZeroPageX, 2, 6)) catch unreachable;
    opcodes.put(0xEE, Opcode.init("INC", AddressingMode.Absolute, 3, 6)) catch unreachable;
    opcodes.put(0xFE, Opcode.init("INC", AddressingMode.AbsoluteX, 3, 7)) catch unreachable;

    // INX: Increment Register X by One
    opcodes.put(0xE8, Opcode.init("INX", AddressingMode.Implied, 1, 2)) catch unreachable;

    // INY: Increment Register Y by One
    opcodes.put(0xC8, Opcode.init("INY", AddressingMode.Implied, 1, 2)) catch unreachable;

    // JMP: Jump to New Location
    opcodes.put(0x4C, Opcode.init("JMP", AddressingMode.Absolute, 3, 3)) catch unreachable;
    opcodes.put(0x6C, Opcode.init("JMP", AddressingMode.Indirect, 3, 5)) catch unreachable;

    // JSR: Jump to New Location Saving Retutn Address
    opcodes.put(0x20, Opcode.init("JSR", AddressingMode.Absolute, 3, 6)) catch unreachable;

    // LDA: Load Accumulator with Memory
    opcodes.put(0xA9, Opcode.init("LDA", AddressingMode.Immediate, 2, 2)) catch unreachable;
    opcodes.put(0xA5, Opcode.init("LDA", AddressingMode.ZeroPage, 2, 3)) catch unreachable;
    opcodes.put(0xB5, Opcode.init("LDA", AddressingMode.ZeroPageX, 2, 4)) catch unreachable;
    opcodes.put(0xAD, Opcode.init("LDA", AddressingMode.Absolute, 3, 4)) catch unreachable;
    opcodes.put(0xBD, Opcode.init("LDA", AddressingMode.AbsoluteX, 3, 4)) catch unreachable;
    opcodes.put(0xB9, Opcode.init("LDA", AddressingMode.AbsoluteY, 3, 4)) catch unreachable;
    opcodes.put(0xA1, Opcode.init("LDA", AddressingMode.IndirectX, 2, 6)) catch unreachable;
    opcodes.put(0xB1, Opcode.init("LDA", AddressingMode.IndirectY, 2, 5)) catch unreachable;

    // LDX: Load Register X with Memory
    opcodes.put(0xA2, Opcode.init("LDX", AddressingMode.Immediate, 2, 2)) catch unreachable;
    opcodes.put(0xA6, Opcode.init("LDX", AddressingMode.ZeroPage, 2, 3)) catch unreachable;
    opcodes.put(0xB6, Opcode.init("LDX", AddressingMode.ZeroPageY, 2, 4)) catch unreachable;
    opcodes.put(0xAE, Opcode.init("LDX", AddressingMode.Absolute, 3, 4)) catch unreachable;
    opcodes.put(0xBE, Opcode.init("LDX", AddressingMode.AbsoluteY, 3, 4)) catch unreachable;

    // LDY: Load Register Y with Memory
    opcodes.put(0xA0, Opcode.init("LDY", AddressingMode.Immediate, 2, 2)) catch unreachable;
    opcodes.put(0xA4, Opcode.init("LDY", AddressingMode.ZeroPage, 2, 3)) catch unreachable;
    opcodes.put(0xB4, Opcode.init("LDY", AddressingMode.ZeroPageX, 2, 4)) catch unreachable;
    opcodes.put(0xAC, Opcode.init("LDY", AddressingMode.Absolute, 3, 4)) catch unreachable;
    opcodes.put(0xBC, Opcode.init("LDY", AddressingMode.AbsoluteX, 3, 4)) catch unreachable;

    // LSR: Shift Ont Bit Right (Memory or Accumulator)
    opcodes.put(0x4A, Opcode.init("LSR", AddressingMode.Accumulator, 1, 2)) catch unreachable;
    opcodes.put(0x46, Opcode.init("LSR", AddressingMode.ZeroPage, 2, 5)) catch unreachable;
    opcodes.put(0x56, Opcode.init("LSR", AddressingMode.ZeroPageX, 2, 6)) catch unreachable;
    opcodes.put(0x4E, Opcode.init("LSR", AddressingMode.Absolute, 3, 6)) catch unreachable;
    opcodes.put(0x5E, Opcode.init("LSR", AddressingMode.AbsoluteX, 3, 7)) catch unreachable;

    // NOP: No Operation
    opcodes.put(0xEA, Opcode.init("NOP", AddressingMode.Implied, 1, 2)) catch unreachable;

    // ORA: OR Memory with Accumulator
    opcodes.put(0x09, Opcode.init("ORA", AddressingMode.Immediate, 2, 2)) catch unreachable;
    opcodes.put(0x05, Opcode.init("ORA", AddressingMode.ZeroPage, 2, 3)) catch unreachable;
    opcodes.put(0x15, Opcode.init("ORA", AddressingMode.ZeroPageX, 2, 4)) catch unreachable;
    opcodes.put(0x0D, Opcode.init("ORA", AddressingMode.Absolute, 3, 4)) catch unreachable;
    opcodes.put(0x1D, Opcode.init("ORA", AddressingMode.AbsoluteX, 3, 4)) catch unreachable;
    opcodes.put(0x19, Opcode.init("ORA", AddressingMode.AbsoluteY, 3, 4)) catch unreachable;
    opcodes.put(0x01, Opcode.init("ORA", AddressingMode.IndirectX, 2, 6)) catch unreachable;
    opcodes.put(0x11, Opcode.init("ORA", AddressingMode.IndirectY, 2, 5)) catch unreachable;

    // PHA: Push Accumulator on Stack
    opcodes.put(0x48, Opcode.init("PHA", AddressingMode.Implied, 1, 3)) catch unreachable;

    // PHP: Push Processor Status on Stack
    opcodes.put(0x08, Opcode.init("PHP", AddressingMode.Implied, 1, 3)) catch unreachable;

    // PLA: Pull Accumulator from Stack
    opcodes.put(0x68, Opcode.init("PLA", AddressingMode.Implied, 1, 4)) catch unreachable;

    // PLP: Pull Processor Status from Stack
    opcodes.put(0x28, Opcode.init("PLP", AddressingMode.Implied, 1, 4)) catch unreachable;

    // ROL: Rotate Ont Bit Left (Memory or Accumulator)
    opcodes.put(0x2A, Opcode.init("ROL", AddressingMode.Accumulator, 1, 2)) catch unreachable;
    opcodes.put(0x26, Opcode.init("ROL", AddressingMode.ZeroPage, 2, 5)) catch unreachable;
    opcodes.put(0x36, Opcode.init("ROL", AddressingMode.ZeroPageX, 2, 6)) catch unreachable;
    opcodes.put(0x2E, Opcode.init("ROL", AddressingMode.Absolute, 3, 6)) catch unreachable;
    opcodes.put(0x3E, Opcode.init("ROL", AddressingMode.AbsoluteX, 3, 7)) catch unreachable;

    // ROR: Rotate Ont Bit Right (Memory or Accumulator)
    opcodes.put(0x6A, Opcode.init("ROR", AddressingMode.Accumulator, 1, 2)) catch unreachable;
    opcodes.put(0x66, Opcode.init("ROR", AddressingMode.ZeroPage, 2, 5)) catch unreachable;
    opcodes.put(0x76, Opcode.init("ROR", AddressingMode.ZeroPageX, 2, 6)) catch unreachable;
    opcodes.put(0x6E, Opcode.init("ROR", AddressingMode.Absolute, 3, 6)) catch unreachable;
    opcodes.put(0x7E, Opcode.init("ROR", AddressingMode.AbsoluteX, 3, 7)) catch unreachable;

    // RTI: Return from Interrupt
    opcodes.put(0x40, Opcode.init("RTI", AddressingMode.Implied, 1, 6)) catch unreachable;

    // RTS: Return from Subroutine
    opcodes.put(0x60, Opcode.init("RTS", AddressingMode.Implied, 1, 6)) catch unreachable;

    // SBC: Substruct Memory from Accumulator with Borrow
    opcodes.put(0xE9, Opcode.init("SBC", AddressingMode.Immediate, 2, 2)) catch unreachable;
    opcodes.put(0xE5, Opcode.init("SBC", AddressingMode.ZeroPage, 2, 3)) catch unreachable;
    opcodes.put(0xF5, Opcode.init("SBC", AddressingMode.ZeroPageX, 2, 4)) catch unreachable;
    opcodes.put(0xED, Opcode.init("SBC", AddressingMode.Absolute, 3, 4)) catch unreachable;
    opcodes.put(0xFD, Opcode.init("SBC", AddressingMode.AbsoluteX, 3, 4)) catch unreachable;
    opcodes.put(0xF9, Opcode.init("SBC", AddressingMode.AbsoluteY, 3, 4)) catch unreachable;
    opcodes.put(0xE1, Opcode.init("SBC", AddressingMode.IndirectX, 2, 6)) catch unreachable;
    opcodes.put(0xF1, Opcode.init("SBC", AddressingMode.IndirectY, 2, 5)) catch unreachable;

    // SEC: Set Carry Flag
    opcodes.put(0x38, Opcode.init("SEC", AddressingMode.Implied, 1, 2)) catch unreachable;

    // SED: Set Deciamal Flag
    opcodes.put(0xF8, Opcode.init("SED", AddressingMode.Implied, 1, 2)) catch unreachable;

    // SEI: Set Interrupt Disable Flag
    opcodes.put(0x78, Opcode.init("SEI", AddressingMode.Implied, 1, 2)) catch unreachable;

    // STA: Store Accumulator in Memory
    opcodes.put(0x85, Opcode.init("STA", AddressingMode.ZeroPage, 2, 3)) catch unreachable;
    opcodes.put(0x95, Opcode.init("STA", AddressingMode.ZeroPageX, 2, 4)) catch unreachable;
    opcodes.put(0x8D, Opcode.init("STA", AddressingMode.Absolute, 3, 4)) catch unreachable;
    opcodes.put(0x9D, Opcode.init("STA", AddressingMode.AbsoluteX, 3, 5)) catch unreachable;
    opcodes.put(0x99, Opcode.init("STA", AddressingMode.AbsoluteY, 3, 5)) catch unreachable;
    opcodes.put(0x81, Opcode.init("STA", AddressingMode.IndirectX, 2, 6)) catch unreachable;
    opcodes.put(0x91, Opcode.init("STA", AddressingMode.IndirectY, 2, 6)) catch unreachable;

    // STX: Store Register X in Memory
    opcodes.put(0x86, Opcode.init("STX", AddressingMode.ZeroPage, 2, 3)) catch unreachable;
    opcodes.put(0x96, Opcode.init("STX", AddressingMode.ZeroPageY, 2, 4)) catch unreachable;
    opcodes.put(0x8E, Opcode.init("STX", AddressingMode.Absolute, 3, 4)) catch unreachable;

    // STY: Store Register Y in Memory
    opcodes.put(0x84, Opcode.init("STY", AddressingMode.ZeroPage, 2, 3)) catch unreachable;
    opcodes.put(0x94, Opcode.init("STY", AddressingMode.ZeroPageX, 2, 4)) catch unreachable;
    opcodes.put(0x8C, Opcode.init("STY", AddressingMode.Absolute, 3, 4)) catch unreachable;

    // TAX: Transfer Accumulator to Register X
    opcodes.put(0xAA, Opcode.init("TAX", AddressingMode.Implied, 1, 2)) catch unreachable;

    // TAY: Transfer Accumulator to Register Y
    opcodes.put(0xA8, Opcode.init("TAY", AddressingMode.Implied, 1, 2)) catch unreachable;

    // TSX: Transfer Stack Pointer to Register X
    opcodes.put(0xBA, Opcode.init("TSX", AddressingMode.Implied, 1, 2)) catch unreachable;

    // TXA: Transfer Register X to Accumulator
    opcodes.put(0x8A, Opcode.init("TXA", AddressingMode.Implied, 1, 2)) catch unreachable;

    // TXS: Transfer Register X to Stack Register
    opcodes.put(0x9A, Opcode.init("TXS", AddressingMode.Implied, 1, 2)) catch unreachable;

    // TYA: Transfer Register Y to Accumulator
    opcodes.put(0x98, Opcode.init("TYA", AddressingMode.Implied, 1, 2)) catch unreachable;

    // unofficial opcodes
    // opcodes.put(0x9A, Opcode.init("TYA", AddressingMode.Implied, 1, 2)) catch unreachable;

    return opcodes;
}
