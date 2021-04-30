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
    AND,
    ASL,
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
    DEC,
    DEX,
    DEY,
    EOR,
    INC,
    INX,
    INY,
    JMP,
    JSR,
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
    ROL,
    ROR,
    RTI,
    RTS,
    SBC,
    SEC,
    SED,
    SEI,
    STA,
    STX,
    STY,
    TAX,
    TAY,
    TSX,
    TXA,
    TXS,
    TYA,
};

pub const Opcode = struct {
    name: OpcodeName,
    code: u8, // just for better way to output, I guess
    addressing_mode: AddressingMode,
    bytes: u8,
    cycles: u8,

    pub fn init(name: OpcodeName, code: u8, addressing_mode: AddressingMode, bytes: u8, cycles: u8) Opcode {
        return Opcode{
            .name = name,
            .code = code,
            .addressing_mode = addressing_mode,
            .bytes = bytes,
            .cycles = cycles,
        };
    }
};

pub fn generateOpcodes() [0x100]Opcode {
    var opcodes: [0x100]Opcode = undefined;

    opcodes[0x00] = Opcode.init(OpcodeName.BRK, 0x00, AddressingMode.Implied, 1, 7);
    // opcodes[0x01] =
    // opcodes[0x02] =
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
    opcodes[0x69] = Opcode.init(OpcodeName.ADC, 0x69, AddressingMode.Immediate, 2, 2);
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
    opcodes[0xA9] = Opcode.init(OpcodeName.BRK, 0xA9, AddressingMode.Immediate, 2, 2);
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

    return opcodes;
}