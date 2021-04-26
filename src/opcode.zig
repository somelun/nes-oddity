pub const AddressingMode = enum {
    Implicit,
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
    name: [_]u8,
    adressing_mode: AdressingMode,
};
