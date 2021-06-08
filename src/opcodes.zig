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

pub const OpcodeName = enum {
    ADC,
    AHX, // illegal
    ANC, // illegal
    AND,
    ARR, // illegal
    ASL,
    AXS, // illegal
    BCC,
    BCS,
    BEQ,
    BIT,
    BMI,
    BNE,
    BPL,
    BRK,
    BVC,
    BVS,
    CLC,
    CLD,
    CLI,
    CLV,
    CMP,
    CPX,
    CPY,
    DCP, //illegal
    DEC,
    DEX,
    DEY,
    EOR,
    INC,
    INX,
    INY,
    ISC, // illegal
    JMP,
    JSR,
    KIL, // illegal
    LAS, // illegal
    LAX, // illegal
    LDA,
    LDX,
    LDY,
    LSR,
    NOP,
    ORA,
    PHA,
    PHP,
    PLA,
    PLP,
    RLA, // illegal
    ROL,
    ROR,
    RRA, // illegal
    RTI,
    RTS,
    SAX, // illegal
    SBC, // hm ?
    SEC,
    SED,
    SEI,
    SHX, // illegal
    SHY, // illegal
    SLO, // illegal
    SRE, // illegal
    STA,
    STX,
    STY,
    TAS, // illegal
    TAX,
    TAY,
    TSX,
    TXA,
    TXS,
    TYA,
    XAA, //illegal
};

pub const Opcode = struct {
    name: OpcodeName,
    addressing_mode: AddressingMode,
    bytes: u8,
    cycles: u8,

    pub fn init(name: OpcodeName, addressing_mode: AddressingMode, bytes: u8, cycles: u8) Opcode {
        return Opcode{
            .name = name,
            .addressing_mode = addressing_mode,
            .bytes = bytes,
            .cycles = cycles,
        };
    }
};

// var _opcodes: comptime [0x100]Opcode = foo();

// fn foo() [0x100]Opcode {
//     // var opcodes: [0x100]Opcode;
//     opcodes[0x00] = Opcode.init(OpcodeName.BRK, AddressingMode.Implied, 1, 7);
//     opcodes[0x01] = Opcode.init(OpcodeName.ORA, AddressingMode.IndirectX, 2, 6);
//     opcodes[0x02] = Opcode.init(OpcodeName.NOP, AddressingMode.IndirectX, 1, 2);

// opcodes[0x03] =
// opcodes[0x04] =
// opcodes[0x05] =
// opcodes[0x06] =
// opcodes[0x07] =
// opcodes[0x08] =
// opcodes[0x09] = Opcode.init(OpcodeName.LDA, 0x00, AddressingMode.Implicit, 1, 7);
// opcodes[0x0A] =
// opcodes[0x0B] =
// opcodes[0x0C] =
// opcodes[0x0D] =
// opcodes[0x0E] =
// opcodes[0x0F] =
// opcodes[0x10] =
// opcodes[0x11] =
// opcodes[0x12] =
// opcodes[0x13] =
// opcodes[0x14] =
// opcodes[0x15] =
// opcodes[0x16] =
// opcodes[0x17] =
// opcodes[0x18] =
// opcodes[0x19] =
// opcodes[0x1A] =
// opcodes[0x1B] =
// opcodes[0x1C] =
// opcodes[0x1D] =
// opcodes[0x1E] =
// opcodes[0x1F] =
// opcodes[0x20] =
// opcodes[0x21] =
// opcodes[0x22] =
// opcodes[0x23] =
// opcodes[0x24] =
// opcodes[0x25] =
// opcodes[0x26] =
// opcodes[0x27] =
// opcodes[0x28] =
// opcodes[0x29] =
// opcodes[0x2A] =
// opcodes[0x2B] =
// opcodes[0x2C] =
// opcodes[0x2D] =
// opcodes[0x2E] =
// opcodes[0x2F] =
// opcodes[0x30] =
// opcodes[0x31] =
// opcodes[0x32] =
// opcodes[0x33] =
// opcodes[0x34] =
// opcodes[0x35] =
// opcodes[0x36] =
// opcodes[0x37] =
// opcodes[0x38] =
// opcodes[0x39] =
// opcodes[0x3A] =
// opcodes[0x3B] =
// opcodes[0x3C] =
// opcodes[0x3D] =
// opcodes[0x3E] =
// opcodes[0x3F] =
// opcodes[0x40] =
// opcodes[0x41] =
// opcodes[0x42] =
// opcodes[0x43] =
// opcodes[0x44] =
// opcodes[0x45] =
// opcodes[0x46] =
// opcodes[0x47] =
// opcodes[0x48] =
// opcodes[0x49] =
// opcodes[0x4A] =
// opcodes[0x4B] =
// opcodes[0x4C] =
// opcodes[0x4D] =
// opcodes[0x4E] =
// opcodes[0x4F] =
// opcodes[0x50] =
// opcodes[0x51] =
// opcodes[0x52] =
// opcodes[0x53] =
// opcodes[0x54] =
// opcodes[0x55] =
// opcodes[0x56] =
// opcodes[0x57] =
// opcodes[0x58] =
// opcodes[0x59] =
// opcodes[0x5A] =
// opcodes[0x5B] =
// opcodes[0x5C] =
// opcodes[0x5D] =
// opcodes[0x5E] =
// opcodes[0x5F] =
// opcodes[0x60] =
// opcodes[0x61] =
// opcodes[0x62] =
// opcodes[0x63] =
// opcodes[0x64] =
// opcodes[0x65] =
// opcodes[0x66] =
// opcodes[0x67] =
// opcodes[0x68] =
// opcodes[0x69] = Opcode.init(OpcodeName.ADC, 0x69, AddressingMode.Immediate, 2, 2);
// opcodes[0x6A] =
// opcodes[0x6B] =
// opcodes[0x6C] =
// opcodes[0x6D] =
// opcodes[0x6E] =
// opcodes[0x6F] =
// opcodes[0x70] =
// opcodes[0x71] =
// opcodes[0x72] =
// opcodes[0x73] =
// opcodes[0x74] =
// opcodes[0x75] =
// opcodes[0x76] =
// opcodes[0x77] =
// opcodes[0x78] =
// opcodes[0x79] =
// opcodes[0x7A] =
// opcodes[0x7B] =
// opcodes[0x7C] =
// opcodes[0x7D] =
// opcodes[0x7E] =
// opcodes[0x7F] =
// opcodes[0x80] =
// opcodes[0x81] =
// opcodes[0x82] =
// opcodes[0x83] =
// opcodes[0x84] =
// opcodes[0x85] =
// opcodes[0x86] =
// opcodes[0x87] =
// opcodes[0x88] =
// opcodes[0x89] =
// opcodes[0x8A] =
// opcodes[0x8B] =
// opcodes[0x8C] =
// opcodes[0x8D] =
// opcodes[0x8E] =
// opcodes[0x8F] =
// opcodes[0x90] =
// opcodes[0x91] =
// opcodes[0x92] =
// opcodes[0x93] =
// opcodes[0x94] =
// opcodes[0x95] =
// opcodes[0x96] =
// opcodes[0x97] =
// opcodes[0x98] =
// opcodes[0x99] =
// opcodes[0x9A] =
// opcodes[0x9B] =
// opcodes[0x9C] =
// opcodes[0x9D] =
// opcodes[0x9E] =
// opcodes[0x9F] =
// opcodes[0xA0] =
// opcodes[0xA1] =
// opcodes[0xA2] =
// opcodes[0xA3] =
// opcodes[0xA4] =
// opcodes[0xA5] =
// opcodes[0xA6] =
// opcodes[0xA7] =
// opcodes[0xA8] =
// opcodes[0xA9] = Opcode.init(OpcodeName.BRK, 0xA9, AddressingMode.Immediate, 2, 2);
// opcodes[0xAA] =
// opcodes[0xAB] =
// opcodes[0xAC] =
// opcodes[0xAD] =
// opcodes[0xAE] =
// opcodes[0xAF] =
// opcodes[0xB0] =
// opcodes[0xB1] =
// opcodes[0xB2] =
// opcodes[0xB3] =
// opcodes[0xB4] =
// opcodes[0xB5] =
// opcodes[0xB6] =
// opcodes[0xB7] =
// opcodes[0xB8] =
// opcodes[0xB9] =
// opcodes[0xBA] =
// opcodes[0xBB] =
// opcodes[0xBC] =
// opcodes[0xBD] =
// opcodes[0xBE] =
// opcodes[0xBF] =
// opcodes[0xC0] =
// opcodes[0xC1] =
// opcodes[0xC2] =
// opcodes[0xC3] =
// opcodes[0xC4] =
// opcodes[0xC5] =
// opcodes[0xC6] =
// opcodes[0xC7] =
// opcodes[0xC8] =
// opcodes[0xC9] =
// opcodes[0xCA] =
// opcodes[0xCB] =
// opcodes[0xCC] =
// opcodes[0xCD] =
// opcodes[0xCE] =
// opcodes[0xCF] =
// opcodes[0xD0] =
// opcodes[0xD1] =
// opcodes[0xD2] =
// opcodes[0xD3] =
// opcodes[0xD4] =
// opcodes[0xD5] =
// opcodes[0xD6] =
// opcodes[0xD7] =
// opcodes[0xD8] =
// opcodes[0xD9] =
// opcodes[0xDA] =
// opcodes[0xDB] =
// opcodes[0xDC] =
// opcodes[0xDD] =
// opcodes[0xDE] =
// opcodes[0xDF] =
// opcodes[0xE0] =
// opcodes[0xE1] =
// opcodes[0xE2] =
// opcodes[0xE3] =
// opcodes[0xE4] =
// opcodes[0xE5] =
// opcodes[0xE6] =
// opcodes[0xE7] =
// opcodes[0xE8] =
// opcodes[0xE9] =
// opcodes[0xEA] =
// opcodes[0xEB] =
// opcodes[0xEC] =
// opcodes[0xED] =
// opcodes[0xEE] =
// opcodes[0xEF] =
// opcodes[0xF0] =
// opcodes[0xF1] =
// opcodes[0xF2] =
// opcodes[0xF3] =
// opcodes[0xF4] =
// opcodes[0xF5] =
// opcodes[0xF6] =
// opcodes[0xF7] =
// opcodes[0xF8] =
// opcodes[0xF9] =
// opcodes[0xFA] =
// opcodes[0xFB] =
// opcodes[0xFC] =
// opcodes[0xFD] =
// opcodes[0xFE] =
// opcodes[0xFF] =
// return opcodes;
// }

// https://www.masswerk.at/6502/6502_instruction_set.html
pub fn generateOpcodes() AutoHashMap(u8, Opcode) {
    var opcodes = AutoHashMap(u8, Opcode).init(std.heap.page_allocator);

    // ADC: Add Memory to Accumulator with Carry
    opcodes.put(0x69, Opcode.init(OpcodeName.ADC, AddressingMode.Immediate, 2, 2)) catch unreachable;
    opcodes.put(0x65, Opcode.init(OpcodeName.ADC, AddressingMode.ZeroPage, 2, 3)) catch unreachable;
    opcodes.put(0x75, Opcode.init(OpcodeName.ADC, AddressingMode.ZeroPageX, 2, 4)) catch unreachable;
    opcodes.put(0x6D, Opcode.init(OpcodeName.ADC, AddressingMode.Absolute, 3, 4)) catch unreachable;
    opcodes.put(0x7D, Opcode.init(OpcodeName.ADC, AddressingMode.AbsoluteX, 3, 4)) catch unreachable;
    opcodes.put(0x79, Opcode.init(OpcodeName.ADC, AddressingMode.AbsoluteY, 3, 4)) catch unreachable;
    opcodes.put(0x61, Opcode.init(OpcodeName.ADC, AddressingMode.IndirectX, 2, 6)) catch unreachable;
    opcodes.put(0x71, Opcode.init(OpcodeName.ADC, AddressingMode.IndirectY, 2, 5)) catch unreachable;

    // AND: AND Memory with Accumulator
    opcodes.put(0x29, Opcode.init(OpcodeName.AND, AddressingMode.Immediate, 2, 2)) catch unreachable;
    opcodes.put(0x25, Opcode.init(OpcodeName.AND, AddressingMode.ZeroPage, 2, 3)) catch unreachable;
    opcodes.put(0x35, Opcode.init(OpcodeName.AND, AddressingMode.ZeroPageX, 2, 4)) catch unreachable;
    opcodes.put(0x2D, Opcode.init(OpcodeName.AND, AddressingMode.Absolute, 3, 4)) catch unreachable;
    opcodes.put(0x3D, Opcode.init(OpcodeName.AND, AddressingMode.AbsoluteX, 3, 4)) catch unreachable;
    opcodes.put(0x39, Opcode.init(OpcodeName.AND, AddressingMode.AbsoluteY, 2, 2)) catch unreachable;
    opcodes.put(0x21, Opcode.init(OpcodeName.AND, AddressingMode.IndirectX, 2, 6)) catch unreachable;

    // ASL: Shift Left One Bit (Memory or Accumulator)
    opcodes.put(0x0A, Opcode.init(OpcodeName.ASL, AddressingMode.Accumulator, 1, 2)) catch unreachable;
    opcodes.put(0x06, Opcode.init(OpcodeName.ASL, AddressingMode.ZeroPage, 2, 5)) catch unreachable;
    opcodes.put(0x16, Opcode.init(OpcodeName.ASL, AddressingMode.ZeroPageX, 2, 6)) catch unreachable;
    opcodes.put(0x0E, Opcode.init(OpcodeName.ASL, AddressingMode.Absolute, 3, 6)) catch unreachable;
    opcodes.put(0x1E, Opcode.init(OpcodeName.ASL, AddressingMode.AbsoluteX, 3, 7)) catch unreachable;

    // BCC: Branch on Carry Clear
    opcodes.put(0x90, Opcode.init(OpcodeName.BCC, AddressingMode.Relative, 2, 2)) catch unreachable;

    // BCS: Branch on Carry Set
    opcodes.put(0xB0, Opcode.init(OpcodeName.BCS, AddressingMode.Relative, 2, 2)) catch unreachable;

    // BEQ: Branch on Result Zero
    opcodes.put(0xF0, Opcode.init(OpcodeName.BEQ, AddressingMode.Relative, 2, 2)) catch unreachable;

    // BIT: Test Bits in Memory with Accumulator
    opcodes.put(0x24, Opcode.init(OpcodeName.BIT, AddressingMode.ZeroPage, 2, 3)) catch unreachable;
    opcodes.put(0x2C, Opcode.init(OpcodeName.BIT, AddressingMode.Absolute, 3, 4)) catch unreachable;

    // BMI: Branch on Result Minus
    opcodes.put(0x30, Opcode.init(OpcodeName.BMI, AddressingMode.Relative, 2, 2)) catch unreachable;

    // BNE: Branch on Result not Zero
    opcodes.put(0xD0, Opcode.init(OpcodeName.BNE, AddressingMode.Relative, 2, 2)) catch unreachable;

    // BPL: Branch on Result Plus
    opcodes.put(0x10, Opcode.init(OpcodeName.BPL, AddressingMode.Relative, 2, 2)) catch unreachable;

    // BRK: Force Break
    opcodes.put(0x00, Opcode.init(OpcodeName.BRK, AddressingMode.Implied, 1, 7)) catch unreachable;

    // BVC: Branch on Overflow Clear
    opcodes.put(0x50, Opcode.init(OpcodeName.BPL, AddressingMode.Relative, 2, 2)) catch unreachable;

    // BVS: Branch on Overflow Set
    opcodes.put(0x70, Opcode.init(OpcodeName.BVS, AddressingMode.Relative, 2, 2)) catch unreachable;

    // CLC: Clear Carry Flag
    opcodes.put(0x18, Opcode.init(OpcodeName.CLC, AddressingMode.Implied, 1, 2)) catch unreachable;

    // CLD: Clear Decimal Flag
    opcodes.put(0xD8, Opcode.init(OpcodeName.CLD, AddressingMode.Implied, 1, 2)) catch unreachable;

    // CLI: Clear Interrupt Disable Bit
    opcodes.put(0x58, Opcode.init(OpcodeName.CLI, AddressingMode.Implied, 1, 2)) catch unreachable;

    // CLV: Clear Overlfow Bit
    opcodes.put(0xB8, Opcode.init(OpcodeName.CLV, AddressingMode.Implied, 1, 2)) catch unreachable;

    // CMP: Compare Memory with Accumulator
    opcodes.put(0xC9, Opcode.init(OpcodeName.CMP, AddressingMode.Immediate, 2, 2)) catch unreachable;
    opcodes.put(0xC5, Opcode.init(OpcodeName.CMP, AddressingMode.ZeroPage, 2, 3)) catch unreachable;
    opcodes.put(0xD5, Opcode.init(OpcodeName.CMP, AddressingMode.ZeroPageX, 2, 4)) catch unreachable;
    opcodes.put(0xCD, Opcode.init(OpcodeName.CMP, AddressingMode.Absolute, 3, 4)) catch unreachable;
    opcodes.put(0xDD, Opcode.init(OpcodeName.CMP, AddressingMode.AbsoluteX, 3, 4)) catch unreachable;
    opcodes.put(0xD9, Opcode.init(OpcodeName.CMP, AddressingMode.AbsoluteY, 3, 4)) catch unreachable;
    opcodes.put(0xC1, Opcode.init(OpcodeName.CMP, AddressingMode.IndirectX, 2, 6)) catch unreachable;
    opcodes.put(0xD1, Opcode.init(OpcodeName.CMP, AddressingMode.IndirectY, 2, 5)) catch unreachable;

    // CPX: Compare Memory and Index X
    opcodes.put(0xE0, Opcode.init(OpcodeName.CPX, AddressingMode.Immediate, 2, 2)) catch unreachable;
    opcodes.put(0xE4, Opcode.init(OpcodeName.CPX, AddressingMode.ZeroPage, 2, 3)) catch unreachable;
    opcodes.put(0xEC, Opcode.init(OpcodeName.CPX, AddressingMode.Absolute, 3, 4)) catch unreachable;

    // CPY: Compare Memory and Index Y
    opcodes.put(0xC0, Opcode.init(OpcodeName.CPY, AddressingMode.Immediate, 2, 2)) catch unreachable;
    opcodes.put(0xC4, Opcode.init(OpcodeName.CPY, AddressingMode.ZeroPage, 2, 3)) catch unreachable;
    opcodes.put(0xCC, Opcode.init(OpcodeName.CPY, AddressingMode.Absolute, 3, 4)) catch unreachable;

    // DEC: Decrement Memory by One
    opcodes.put(0xC6, Opcode.init(OpcodeName.DEC, AddressingMode.ZeroPage, 2, 5)) catch unreachable;
    opcodes.put(0xD6, Opcode.init(OpcodeName.DEC, AddressingMode.ZeroPageX, 2, 6)) catch unreachable;
    opcodes.put(0xCE, Opcode.init(OpcodeName.DEC, AddressingMode.Absolute, 3, 6)) catch unreachable;
    opcodes.put(0xDE, Opcode.init(OpcodeName.DEC, AddressingMode.AbsoluteX, 3, 7)) catch unreachable;

    // DEX: Decrement Index X by One
    opcodes.put(0xCA, Opcode.init(OpcodeName.DEX, AddressingMode.Implied, 1, 2)) catch unreachable;

    // DEY: Decrement Index Y by One
    opcodes.put(0x88, Opcode.init(OpcodeName.DEY, AddressingMode.Implied, 1, 2)) catch unreachable;

    // EOR: Exclusive-OR Memory with Accumulator
    opcodes.put(0x49, Opcode.init(OpcodeName.EOR, AddressingMode.Immediate, 2, 2)) catch unreachable;
    opcodes.put(0x45, Opcode.init(OpcodeName.EOR, AddressingMode.ZeroPage, 2, 3)) catch unreachable;
    opcodes.put(0x55, Opcode.init(OpcodeName.EOR, AddressingMode.ZeroPageX, 2, 4)) catch unreachable;
    opcodes.put(0x4D, Opcode.init(OpcodeName.EOR, AddressingMode.Absolute, 3, 4)) catch unreachable;
    opcodes.put(0x5D, Opcode.init(OpcodeName.EOR, AddressingMode.AbsoluteX, 3, 4)) catch unreachable;
    opcodes.put(0x59, Opcode.init(OpcodeName.EOR, AddressingMode.AbsoluteY, 3, 4)) catch unreachable;
    opcodes.put(0x41, Opcode.init(OpcodeName.EOR, AddressingMode.IndirectX, 2, 6)) catch unreachable;
    opcodes.put(0x51, Opcode.init(OpcodeName.EOR, AddressingMode.IndirectY, 2, 5)) catch unreachable;

    // INC: Increment Memory by One
    opcodes.put(0xE6, Opcode.init(OpcodeName.INC, AddressingMode.ZeroPage, 2, 5)) catch unreachable;
    opcodes.put(0xF6, Opcode.init(OpcodeName.INC, AddressingMode.ZeroPageX, 2, 6)) catch unreachable;
    opcodes.put(0xEE, Opcode.init(OpcodeName.INC, AddressingMode.Absolute, 3, 6)) catch unreachable;
    opcodes.put(0xFE, Opcode.init(OpcodeName.INC, AddressingMode.AbsoluteX, 3, 7)) catch unreachable;

    // INX: Increment Index X by One
    opcodes.put(0xE8, Opcode.init(OpcodeName.INX, AddressingMode.Implied, 1, 2)) catch unreachable;

    // INY: Increment Index Y by One
    opcodes.put(0xC8, Opcode.init(OpcodeName.INY, AddressingMode.Implied, 1, 2)) catch unreachable;

    // JMP: Jump to New Location
    opcodes.put(0x4C, Opcode.init(OpcodeName.JMP, AddressingMode.Absolute, 3, 3)) catch unreachable;
    opcodes.put(0x6C, Opcode.init(OpcodeName.JMP, AddressingMode.Indirect, 3, 5)) catch unreachable;

    // JSR: Jump to New Location Saving Retutn Address
    opcodes.put(0x20, Opcode.init(OpcodeName.JSR, AddressingMode.Absolute, 3, 6)) catch unreachable;

    // LDA: Load Accumulator with Memory
    opcodes.put(0xA9, Opcode.init(OpcodeName.LDA, AddressingMode.Immediate, 2, 2)) catch unreachable;
    opcodes.put(0xA5, Opcode.init(OpcodeName.LDA, AddressingMode.ZeroPage, 2, 3)) catch unreachable;
    opcodes.put(0xB5, Opcode.init(OpcodeName.LDA, AddressingMode.ZeroPageX, 2, 4)) catch unreachable;
    opcodes.put(0xAD, Opcode.init(OpcodeName.LDA, AddressingMode.Absolute, 3, 4)) catch unreachable;
    opcodes.put(0xBD, Opcode.init(OpcodeName.LDA, AddressingMode.AbsoluteX, 3, 4)) catch unreachable;
    opcodes.put(0xB9, Opcode.init(OpcodeName.LDA, AddressingMode.AbsoluteY, 3, 4)) catch unreachable;
    opcodes.put(0xA1, Opcode.init(OpcodeName.LDA, AddressingMode.IndirectX, 2, 6)) catch unreachable;
    opcodes.put(0xB1, Opcode.init(OpcodeName.LDA, AddressingMode.IndirectY, 2, 5)) catch unreachable;

    // LDX: Load Index X with Memory
    opcodes.put(0xA2, Opcode.init(OpcodeName.LDX, AddressingMode.Immediate, 2, 2)) catch unreachable;
    opcodes.put(0xA6, Opcode.init(OpcodeName.LDX, AddressingMode.ZeroPage, 2, 3)) catch unreachable;
    opcodes.put(0xB6, Opcode.init(OpcodeName.LDX, AddressingMode.ZeroPageY, 2, 4)) catch unreachable;
    opcodes.put(0xAE, Opcode.init(OpcodeName.LDX, AddressingMode.Absolute, 3, 4)) catch unreachable;
    opcodes.put(0xBE, Opcode.init(OpcodeName.LDX, AddressingMode.AbsoluteY, 3, 4)) catch unreachable;

    // LDY: Load Index Y with Memory
    opcodes.put(0xA0, Opcode.init(OpcodeName.LDY, AddressingMode.Immediate, 2, 2)) catch unreachable;
    opcodes.put(0xA4, Opcode.init(OpcodeName.LDY, AddressingMode.ZeroPage, 2, 3)) catch unreachable;
    opcodes.put(0xB4, Opcode.init(OpcodeName.LDY, AddressingMode.ZeroPageX, 2, 4)) catch unreachable;
    opcodes.put(0xAC, Opcode.init(OpcodeName.LDY, AddressingMode.Absolute, 3, 4)) catch unreachable;
    opcodes.put(0xBC, Opcode.init(OpcodeName.LDY, AddressingMode.AbsoluteX, 3, 4)) catch unreachable;

    // LSR: Shift Ont Bit Right (Memory or Accumulator)
    opcodes.put(0x4A, Opcode.init(OpcodeName.LSR, AddressingMode.Accumulator, 1, 2)) catch unreachable;
    opcodes.put(0x46, Opcode.init(OpcodeName.LSR, AddressingMode.ZeroPage, 2, 5)) catch unreachable;
    opcodes.put(0x56, Opcode.init(OpcodeName.LSR, AddressingMode.ZeroPageX, 2, 6)) catch unreachable;
    opcodes.put(0x4E, Opcode.init(OpcodeName.LSR, AddressingMode.Absolute, 3, 6)) catch unreachable;
    opcodes.put(0x5E, Opcode.init(OpcodeName.LSR, AddressingMode.AbsoluteX, 3, 7)) catch unreachable;

    // NOP: No Operation
    opcodes.put(0xEA, Opcode.init(OpcodeName.NOP, AddressingMode.Implied, 1, 2)) catch unreachable;

    // ORA: OR Memory with Accumulator
    opcodes.put(0x09, Opcode.init(OpcodeName.ORA, AddressingMode.Immediate, 2, 2)) catch unreachable;
    opcodes.put(0x05, Opcode.init(OpcodeName.ORA, AddressingMode.ZeroPage, 2, 3)) catch unreachable;
    opcodes.put(0x15, Opcode.init(OpcodeName.ORA, AddressingMode.ZeroPageX, 2, 4)) catch unreachable;
    opcodes.put(0x0D, Opcode.init(OpcodeName.ORA, AddressingMode.Absolute, 3, 4)) catch unreachable;
    opcodes.put(0x1D, Opcode.init(OpcodeName.ORA, AddressingMode.AbsoluteX, 3, 4)) catch unreachable;
    opcodes.put(0x19, Opcode.init(OpcodeName.ORA, AddressingMode.AbsoluteY, 3, 4)) catch unreachable;
    opcodes.put(0x01, Opcode.init(OpcodeName.ORA, AddressingMode.IndirectX, 2, 6)) catch unreachable;
    opcodes.put(0x11, Opcode.init(OpcodeName.ORA, AddressingMode.IndirectY, 2, 5)) catch unreachable;

    // PHA: Push Accumulator on Stack
    opcodes.put(0x48, Opcode.init(OpcodeName.PHA, AddressingMode.Implied, 1, 3)) catch unreachable;

    // PHP: Push Processor Status on Stack
    opcodes.put(0x08, Opcode.init(OpcodeName.PHP, AddressingMode.Implied, 1, 3)) catch unreachable;

    // PLA: Pull Accumulator from Stack
    opcodes.put(0x68, Opcode.init(OpcodeName.PLA, AddressingMode.Implied, 1, 4)) catch unreachable;

    // PLP: Pull Processor Status from Stack
    opcodes.put(0x28, Opcode.init(OpcodeName.PLP, AddressingMode.Implied, 1, 4)) catch unreachable;

    // ROL: Rotate Ont Bit Left (Memory or Accumulator)
    opcodes.put(0x2A, Opcode.init(OpcodeName.ROL, AddressingMode.Accumulator, 1, 2)) catch unreachable;
    opcodes.put(0x26, Opcode.init(OpcodeName.ROL, AddressingMode.ZeroPage, 2, 5)) catch unreachable;
    opcodes.put(0x36, Opcode.init(OpcodeName.ROL, AddressingMode.ZeroPageX, 2, 6)) catch unreachable;
    opcodes.put(0x2E, Opcode.init(OpcodeName.ROL, AddressingMode.Absolute, 3, 6)) catch unreachable;
    opcodes.put(0x3E, Opcode.init(OpcodeName.ROL, AddressingMode.AbsoluteX, 3, 7)) catch unreachable;

    // ROR: Rotate Ont Bit Right (Memory or Accumulator)
    opcodes.put(0x6A, Opcode.init(OpcodeName.ROR, AddressingMode.Accumulator, 1, 2)) catch unreachable;
    opcodes.put(0x66, Opcode.init(OpcodeName.ROR, AddressingMode.ZeroPage, 2, 5)) catch unreachable;
    opcodes.put(0x76, Opcode.init(OpcodeName.ROR, AddressingMode.ZeroPageX, 2, 6)) catch unreachable;
    opcodes.put(0x6E, Opcode.init(OpcodeName.ROR, AddressingMode.Absolute, 3, 6)) catch unreachable;
    opcodes.put(0x7E, Opcode.init(OpcodeName.ROR, AddressingMode.AbsoluteX, 3, 7)) catch unreachable;

    // RTI: Return from Interrupt
    opcodes.put(0x40, Opcode.init(OpcodeName.RTI, AddressingMode.Implied, 1, 6)) catch unreachable;

    // RTS: Return from Subroutine
    opcodes.put(0x60, Opcode.init(OpcodeName.RTS, AddressingMode.Implied, 1, 6)) catch unreachable;

    // SBC: Substruct Memory from Accumulator with Borrow
    opcodes.put(0xE9, Opcode.init(OpcodeName.SBC, AddressingMode.Immediate, 2, 2)) catch unreachable;
    opcodes.put(0xE5, Opcode.init(OpcodeName.SBC, AddressingMode.ZeroPage, 2, 3)) catch unreachable;
    opcodes.put(0xF5, Opcode.init(OpcodeName.SBC, AddressingMode.ZeroPageX, 2, 4)) catch unreachable;
    opcodes.put(0xED, Opcode.init(OpcodeName.SBC, AddressingMode.Absolute, 3, 4)) catch unreachable;
    opcodes.put(0xFD, Opcode.init(OpcodeName.SBC, AddressingMode.AbsoluteX, 3, 4)) catch unreachable;
    opcodes.put(0xF9, Opcode.init(OpcodeName.SBC, AddressingMode.AbsoluteY, 3, 4)) catch unreachable;
    opcodes.put(0xE1, Opcode.init(OpcodeName.SBC, AddressingMode.IndirectX, 2, 6)) catch unreachable;
    opcodes.put(0xF1, Opcode.init(OpcodeName.SBC, AddressingMode.IndirectY, 2, 5)) catch unreachable;

    // SEC: Set Carry Flag
    opcodes.put(0x38, Opcode.init(OpcodeName.SEC, AddressingMode.Implied, 1, 2)) catch unreachable;

    // SED: Set Deciamal Flag
    opcodes.put(0xF8, Opcode.init(OpcodeName.SED, AddressingMode.Implied, 1, 2)) catch unreachable;

    // SEI: Set Interrupt Disable Flag
    opcodes.put(0x78, Opcode.init(OpcodeName.SEI, AddressingMode.Implied, 1, 2)) catch unreachable;

    // STA: Store Accumulator in Memory
    opcodes.put(0x85, Opcode.init(OpcodeName.STA, AddressingMode.ZeroPage, 2, 3)) catch unreachable;
    opcodes.put(0x95, Opcode.init(OpcodeName.STA, AddressingMode.ZeroPageX, 2, 4)) catch unreachable;
    opcodes.put(0x8D, Opcode.init(OpcodeName.STA, AddressingMode.Absolute, 3, 4)) catch unreachable;
    opcodes.put(0x9D, Opcode.init(OpcodeName.STA, AddressingMode.AbsoluteX, 3, 5)) catch unreachable;
    opcodes.put(0x99, Opcode.init(OpcodeName.STA, AddressingMode.AbsoluteY, 3, 5)) catch unreachable;
    opcodes.put(0x81, Opcode.init(OpcodeName.STA, AddressingMode.IndirectX, 2, 6)) catch unreachable;
    opcodes.put(0x91, Opcode.init(OpcodeName.STA, AddressingMode.IndirectY, 2, 6)) catch unreachable;

    // STX: Store Index X in Memory
    opcodes.put(0x86, Opcode.init(OpcodeName.STX, AddressingMode.ZeroPage, 2, 3)) catch unreachable;
    opcodes.put(0x96, Opcode.init(OpcodeName.STX, AddressingMode.ZeroPageY, 2, 4)) catch unreachable;
    opcodes.put(0x8E, Opcode.init(OpcodeName.STX, AddressingMode.Absolute, 3, 4)) catch unreachable;

    // STY: Store Index Y in Memory
    opcodes.put(0x84, Opcode.init(OpcodeName.STY, AddressingMode.ZeroPage, 2, 3)) catch unreachable;
    opcodes.put(0x94, Opcode.init(OpcodeName.STY, AddressingMode.ZeroPageX, 2, 4)) catch unreachable;
    opcodes.put(0x8C, Opcode.init(OpcodeName.STY, AddressingMode.Absolute, 3, 4)) catch unreachable;

    // TAX: Transfer Accumulator to Index X
    opcodes.put(0xAA, Opcode.init(OpcodeName.TAX, AddressingMode.Implied, 1, 2)) catch unreachable;

    // TAY: Transfer Accumulator to Index Y
    opcodes.put(0xA8, Opcode.init(OpcodeName.TAY, AddressingMode.Implied, 1, 2)) catch unreachable;

    // TSX: Transfer Stack Pointer to Index X
    opcodes.put(0xBA, Opcode.init(OpcodeName.TSX, AddressingMode.Implied, 1, 2)) catch unreachable;

    // TXA: Transfer Index X to Accumulator
    opcodes.put(0x8A, Opcode.init(OpcodeName.TXA, AddressingMode.Implied, 1, 2)) catch unreachable;

    // TXS: Transfer Index X to Stack Register
    opcodes.put(0x8A, Opcode.init(OpcodeName.TXS, AddressingMode.Implied, 1, 2)) catch unreachable;

    // TYA: Transfer Index Y to Accumulator
    opcodes.put(0x98, Opcode.init(OpcodeName.TYA, AddressingMode.Implied, 1, 2)) catch unreachable;

    return opcodes;
}
