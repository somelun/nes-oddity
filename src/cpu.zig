const std = @import("std");
const AutoHashMap = std.AutoHashMap;

const Bus = @import("bus.zig").Bus;
const OpcodesAPI = @import("opcodes.zig");
const Opcode = OpcodesAPI.Opcode;
const AddressingMode = OpcodesAPI.AddressingMode;

const Tracer = @import("tracer.zig");

// all the games keep initial PC value at this address
const PC_ADDRESS: u16 = 0xFFFC;

const StatusFlag = enum(u8) {
    C = (1 << 0), // carry
    Z = (1 << 1), // zero
    I = (1 << 2), // interrupt disable
    D = (1 << 3), // decimal
    B = (1 << 4), // break
    U = (1 << 5), // unused?
    V = (1 << 6), // overflow
    N = (1 << 7), // negative
};

pub const CPU = struct {
    register_a: u8 = 0x00,
    register_x: u8 = 0x00,
    register_y: u8 = 0x00,
    status: u8 = 0x24, //set D and B to 1
    program_counter: u16 = 0x0000,
    stack_pointer: u8 = 0xFD,

    bus: *Bus = undefined,
    opcodes: AutoHashMap(u8, Opcode),

    // if true, debug trace will be printed (used for nestest.rom)
    debug_trace: bool = false,

    pub fn init(bus: *Bus) CPU {
        var cpu = CPU{
            .opcodes = OpcodesAPI.generateOpcodes(),
        };
        cpu.bus = bus;

        return cpu;
    }

    pub fn reset(self: *CPU) void {
        self.register_a = 0;
        self.register_x = 0;
        self.status = 0x24; //set D and B to 1

        self.program_counter = self.bus.read16(PC_ADDRESS);
    }

    pub fn loadAndRun(self: *CPU, program_code: []const u8) void {
        self.load(program_code);
        self.reset();
        self.loop();
    }

    pub fn load(self: *CPU, program_code: []const u8) void {
        self.bus.loadProgram(program_code);

        // program counter stored in memory at 0xFFFC
        self.bus.write16(PC_ADDRESS, 0xFFFC);
    }

    pub fn cycle(self: *CPU) u8 {
        if (self.debug_trace) {
            Tracer.trace(self);
        }

        // store initial PC value for the later incrementation if it not
        // changed (for example after branch instruction)
        const initial_pc: u16 = self.program_counter;

        const value: u8 = self.bus.read8(self.program_counter);
        self.program_counter += 1;

        // these flags are unused in the emulation
        self.setFlag(StatusFlag.U, true);
        self.setFlag(StatusFlag.I, true);

        const opcode: ?Opcode = self.opcodes.get(value);
        if (opcode == null) {
            std.debug.print("Unsupported instruction! {X}\n", .{value});
            return 0;
        }

        const addressing_mode: AddressingMode = opcode.?.addressing_mode;

        self.handleOpcode(value, addressing_mode);

        // in the end we increment program counter according to opcode length
        if (self.program_counter == initial_pc + 1) {
            self.program_counter += (opcode.?.length - 1);
        }

        return opcode.?.length;
    }

    // used to tests
    // fn loop(self: *CPU) void {
    //     while (self.program_counter < 0xFFFC) { //TODO: remove magic number
    //         const value: u8 = self.bus.read8(self.program_counter);
    //         self.program_counter += 1;
    //
    //         const opcode: ?Opcode = self.opcodes.get(value);
    //         if (opcode == null) {
    //             continue;
    //         }
    //
    //         const addressing_mode: AddressingMode = opcode.?.addressing_mode;
    //
    //         self.handleOpcode(value, addressing_mode);
    //     }
    // }

    // returns address for the next operand using addressing mode,
    // some instuctions have few modes for the same opcode
    pub fn getOperandAddress(self: *CPU, mode: AddressingMode) u16 {
        var address: u16 = undefined;

        switch (mode) {
            AddressingMode.Implied => {},

            AddressingMode.Accumulator => {
                address = self.register_a;
            },

            AddressingMode.Immediate => {
                address = self.program_counter;
            },

            AddressingMode.ZeroPage => {
                address = self.bus.read8(self.program_counter);
            },

            AddressingMode.ZeroPageX => {
                address = self.bus.read8(self.program_counter) +% self.register_x;
            },

            AddressingMode.ZeroPageY => {
                address = self.bus.read8(self.program_counter) +% self.register_y;
            },

            AddressingMode.Relative => {
                var offset: u8 = self.bus.read8(self.program_counter);
                address = self.program_counter +% offset +% 1;

                // if the offset is negative
                if (offset > 0x7F) {
                    address -= 0x0100;
                }
            },

            AddressingMode.Absolute => {
                address = self.bus.read16(self.program_counter);
            },

            AddressingMode.AbsoluteX => {
                address = self.bus.read16(self.program_counter) +% self.register_x;
            },

            AddressingMode.AbsoluteY => {
                address = self.bus.read16(self.program_counter) +% self.register_y;
            },

            AddressingMode.Indirect => {
                const ptr: u16 = self.bus.read16(self.program_counter);

                // Emulating hardware bug: if low byte is 0xFF, usually we read hight byte of
                // actual address from another page, but this chip wraps address back to the
                // same page TODO: test this please
                if (ptr & 0x00FF == 0x00FF) {
                    address = (@intCast(u16, self.bus.read8(ptr & 0xFF00)) << 8) | self.bus.read8(ptr);
                } else {
                    address = (@intCast(u16, self.bus.read8(ptr + 1)) << 8) | self.bus.read8(ptr);
                }
            },

            AddressingMode.IndirectX => {
                const ptr: u8 = self.bus.read8(self.program_counter) +% self.register_x;

                const lo: u16 = self.bus.read8(ptr);
                const hi: u16 = self.bus.read8(ptr +% 1);
                address = (hi << 8) | (lo);
            },

            AddressingMode.IndirectY => {
                const base: u8 = self.bus.read8(self.program_counter);

                const lo: u16 = self.bus.read8(base);
                const hi: u16 = self.bus.read8(base +% 1);

                const deref = (hi << 8) | (lo);
                address = deref +% self.register_y;
            },
        }

        return address;
    }

    fn handleOpcode(self: *CPU, value: u8, addressing_mode: AddressingMode) void {
        switch (value) {
            // ADC: Add Memory to Accumulator with Carry
            0x69, 0x65, 0x75, 0x6D, 0x7D, 0x79, 0x61, 0x71 => {
                self._adc(addressing_mode);
            },

            // AND: AND Memory with Accumulator
            0x29, 0x25, 0x35, 0x2D, 0x3D, 0x39, 0x21, 0x31 => {
                self._and(addressing_mode);
            },

            // ASL: Shift Left One Bit (Memory or Accumulator)
            0x0A, 0x06, 0x16, 0x0E, 0x1E => {
                self._asl(addressing_mode);
            },

            // BCC: Branch on Carry Clear
            0x90 => {
                self._bcc(addressing_mode);
            },

            // BCS: Branch on Carry Set
            0xB0 => {
                self._bcs(addressing_mode);
            },

            // BEQ: Branch on Result Zero
            0xF0 => {
                self._beq(addressing_mode);
            },

            // BIT: Test Bits in Memory with Accumulator
            0x24, 0x2C => {
                self._bit(addressing_mode);
            },

            // BMI: Branch on Result Minus
            0x30 => {
                self._bmi(addressing_mode);
            },

            // BNE: Branch on Result not Zero
            0xD0 => {
                self._bne(addressing_mode);
            },

            // BPL: Branch on Result Plus
            0x10 => {
                self._bpl(addressing_mode);
            },

            // BRK: Force Break
            0x00 => {
                return;
            },

            // BVC: Branch on Overflow Clear
            0x50 => {
                self._bvc(addressing_mode);
            },

            // BVS: Branch on Overflow Set
            0x70 => {
                self._bvs(addressing_mode);
            },

            // CLC: Clear Carry Flag
            0x18 => {
                self._clc();
            },

            // CLD: Clear Decimal Mode
            0xD8 => {
                self._cld();
            },

            // CLI: Clear Interrupt Disable Bit
            0x58 => {
                self._cli();
            },

            // CLV: Clear Overflow Flag
            0xB8 => {
                self._clv();
            },

            // CMP: Compare Memory with Accumulator
            0xC9, 0xC5, 0xD5, 0xCD, 0xDD, 0xD9, 0xC1, 0xD1 => {
                self._cmp(addressing_mode);
            },

            // CPX: Compare Memory and Index X
            0xE0, 0xE4, 0xEC => {
                self._cpx(addressing_mode);
            },

            // CPY: Compare Memory and Index Y
            0xC0, 0xC4, 0xCC => {
                self._cpy(addressing_mode);
            },

            // DEC: Decrement Memory by One
            0xC6, 0xD6, 0xCE, 0xDE => {
                self._dec(addressing_mode);
            },

            // DEX: Decrement Index X by One
            0xCA => {
                self._dex();
            },

            // DEY: Decrement Index Y by One
            0x88 => {
                self._dey();
            },

            // EOR: Exclusive-OR Memory with Accumulator
            0x49, 0x45, 0x55, 0x4D, 0x5D, 0x59, 0x41, 0x51 => {
                self._eor(addressing_mode);
            },

            // INC: Increment Memory by One
            0xE6, 0xF6, 0xEE, 0xFE => {
                self._inc(addressing_mode);
            },

            // INX: Increment Index X by One
            0xE8 => {
                self._inx();
            },

            // INY: Increment Index Y by One
            0xC8 => {
                self._iny();
            },

            // JMP: Jump to New Location
            0x4C, 0x6C => {
                self._jmp(addressing_mode);
            },

            // JSR: Jump to New Location Saving Return Address
            0x20 => {
                self._jsr(addressing_mode);
            },

            // LDA: Load Accumulator with Memory
            0xA9, 0xA5, 0xB5, 0xAD, 0xBD, 0xB9, 0xA1, 0xB1 => {
                self._lda(addressing_mode);
            },

            // LDX: Load Index X with Memory
            0xA2, 0xA6, 0xB6, 0xAE, 0xBE => {
                self._ldx(addressing_mode);
            },

            // LDY: Load Index Y with Memory
            0xA0, 0xA4, 0xB4, 0xAC, 0xBC => {
                self._ldy(addressing_mode);
            },

            // LSR: Shift One Bit Right (Memory or Accumulator)
            0x4A, 0x46, 0x56, 0x4E, 0x5E => {
                self._lsr(addressing_mode);
            },

            // NOP: No Operation
            0xEA => {
                return;
            },

            // ORA: OR Memory with Accumulator
            0x09, 0x05, 0x15, 0x0D, 0x1D, 0x19, 0x01, 0x11 => {
                self._ora(addressing_mode);
            },

            // PHA: Push Accumulator on Stack
            0x48 => {
                self._pha();
            },

            // PHP: Push Processor Status on Stack
            0x08 => {
                self._php();
            },

            // PLA: Pull Accumulator from Stack
            0x68 => {
                self._pla();
            },

            // PLP: Pull Prepcessor Status from Stack
            0x28 => {
                self._plp();
            },

            // ROL: Rotate One Bit Left (Memory or Accumulator)
            0x2A, 0x26, 0x36, 0x2E, 0x3E => {
                self._rol(addressing_mode);
            },

            // ROR: Rotate One Bit Right (Memory or Accumulator)
            0x6A, 0x66, 0x76, 0x6E, 0x7E => {
                self._ror(addressing_mode);
            },

            // RTI: Return from Interrupt
            0x40 => {
                self._rti();
            },

            // RTS: Return fromm Subroutine
            0x60 => {
                self._rts();
            },

            // SBC: Subtract Memory from Accumulator with Borrow
            0xE9, 0xE5, 0xF5, 0xED, 0xFD, 0xF9, 0xE1, 0xF1 => {
                self._sbc(addressing_mode);
            },

            // SEC: Set Carry Flag
            0x38 => {
                self._sec();
            },

            // SED: Set Decimal Flag
            0xF8 => {
                self._sed();
            },

            // SEI: Set Interrupt Disable Flag
            0x78 => {
                self._sei();
            },

            // STA: Store Accumulator in Memory
            0x85, 0x95, 0x8D, 0x9D, 0x99, 0x81, 0x91 => {
                self._sta(addressing_mode);
            },

            // STX: Store Index X in Memory
            0x86, 0x96, 0x8E => {
                self._stx(addressing_mode);
            },

            // STY: Store Index Y in Memory
            0x84, 0x94, 0x8C => {
                self._sty(addressing_mode);
            },

            // TAX: Transfer Accumulator to Index X
            0xAA => {
                self._tax();
            },

            // TAY: Transfer Accumulator to Index Y
            0xA8 => {
                self._tay();
            },

            // TSX: Transfer Stack Pointer to Index X
            0xBA => {
                self._tsx();
            },

            // TXA: Transfer Index X to Accumulator
            0x8A => {
                self._txa();
            },

            // TXS: Transfer Index X to Stack Pointer
            0x9A => {
                self._txs();
            },

            // TYA: Transfer Index Y to Accumulator
            0x98 => {
                self._tya();
            },

            // unknown instruction or already used data
            else => {},
        }
    }

    ///////////////////////////////////////////////////////
    // Stack Operations

    fn pushToStack(self: *CPU, value: u8) void {
        self.bus.write8(0x0100 + @intCast(u16, self.stack_pointer), value);
        self.decrementStackPointer();
    }

    fn popFromStack(self: *CPU) u8 {
        self.incrementStackPointer();
        return self.bus.read8(0x0100 + @intCast(u16, self.stack_pointer));
    }

    pub fn readFromStack(self: *CPU) u8 {
        self.incrementStackPointer();
        const t: u8 = self.bus.read8(0x0100 + @intCast(u16, self.stack_pointer));
        self.decrementStackPointer();
        return t;
    }

    fn incrementStackPointer(self: *CPU) void {
        self.stack_pointer += 1;
        self.stack_pointer &= 0xFF;
    }

    fn decrementStackPointer(self: *CPU) void {
        self.stack_pointer -= 1;
        self.stack_pointer &= 0xFF;
    }

    ///////////////////////////////////////////////////////
    // Status Flags Operations

    fn updateZeroAndNegativeFlag(self: *CPU, value: u8) void {
        self.updateZeroFlag(value);
        self.updateNegativeFlag(value);
    }

    fn setFlag(self: *CPU, flag: StatusFlag, value: bool) void {
        const number = @enumToInt(flag);
        if (value) {
            self.status = self.status | number;
        } else {
            self.status = self.status & (~number);
        }
    }

    fn getFlag(self: *CPU, flag: StatusFlag) u1 {
        const number = @enumToInt(flag);
        return if (self.status & number > 0) 1 else 0;
    }

    fn updateZeroFlag(self: *CPU, value: u8) void {
        if (value == 0) {
            self.status = self.status | 0b0000_0010;
        } else {
            self.status = self.status & 0b1111_1101;
        }
    }

    fn updateNegativeFlag(self: *CPU, value: u8) void {
        if (value & 0b1000_0000 != 0) {
            self.status = self.status | 0b1000_0000;
        } else {
            self.status = self.status & 0b0111_1111;
        }
    }

    ///////////////////////////////////////////////////////
    // Instructions

    fn _adc(self: *CPU, mode: AddressingMode) void {
        const address: u16 = self.getOperandAddress(mode);
        const fetched: u16 = @intCast(u16, self.bus.read8(address));

        const result: u16 = @intCast(u16, self.register_a) + fetched + @intCast(u16, self.getFlag(StatusFlag.C));

        self.setFlag(StatusFlag.C, result > 0xFF);
        self.setFlag(StatusFlag.V, (~(@intCast(u16, self.register_a) ^ fetched) & (@intCast(u16, self.register_a) ^ result)) & 0x0080 != 0);
        self.updateZeroAndNegativeFlag(@intCast(u8, result & 0x00FF));

        self.register_a = @intCast(u8, result & 0x00FF);
    }

    fn _and(self: *CPU, mode: AddressingMode) void {
        const address: u16 = self.getOperandAddress(mode);
        self.register_a = self.register_a & self.bus.read8(address);

        self.updateZeroAndNegativeFlag(self.register_a);
    }

    fn _asl(self: *CPU, mode: AddressingMode) void {
        if (mode == AddressingMode.Accumulator) {
            self.setFlag(StatusFlag.C, (self.register_a >> 7) == 1);
            self.register_a <<= 1;

            self.updateZeroAndNegativeFlag(self.register_a);
        } else {
            const address: u16 = self.getOperandAddress(mode);
            var fetched: u8 = self.bus.read8(address);

            self.setFlag(StatusFlag.C, (fetched >> 7) == 1);
            fetched <<= 1;

            self.updateZeroAndNegativeFlag(fetched);
            self.bus.write8(address, fetched);
        }
    }

    fn _bcc(self: *CPU, mode: AddressingMode) void {
        const address: u16 = self.getOperandAddress(mode);
        if (self.getFlag(StatusFlag.C) == 0) {
            self.program_counter = address;
        }
    }

    fn _bcs(self: *CPU, mode: AddressingMode) void {
        const address: u16 = self.getOperandAddress(mode);
        if (self.getFlag(StatusFlag.C) == 1) {
            self.program_counter = address;
        }
    }

    fn _beq(self: *CPU, mode: AddressingMode) void {
        const address: u16 = self.getOperandAddress(mode);
        if (self.getFlag(StatusFlag.Z) == 1) {
            self.program_counter = address;
        }
    }

    fn _bit(self: *CPU, mode: AddressingMode) void {
        const address: u16 = self.getOperandAddress(mode);
        const fetched = self.bus.read8(address);
        const value: u8 = self.register_a & fetched;

        self.setFlag(StatusFlag.Z, value == 0);
        self.setFlag(StatusFlag.V, (fetched & (1 << 6)) > 0);
        self.setFlag(StatusFlag.N, (fetched & (1 << 7)) > 0);
    }

    fn _bmi(self: *CPU, mode: AddressingMode) void {
        const address: u16 = self.getOperandAddress(mode);
        if (self.getFlag(StatusFlag.N) == 1) {
            self.program_counter = address;
        }
    }

    fn _bne(self: *CPU, mode: AddressingMode) void {
        const address: u16 = self.getOperandAddress(mode);
        if (self.getFlag(StatusFlag.Z) == 0) {
            self.program_counter = address;
        }
    }

    fn _bpl(self: *CPU, mode: AddressingMode) void {
        const address: u16 = self.getOperandAddress(mode);
        if (self.getFlag(StatusFlag.N) == 0) {
            self.program_counter = address;
        }
    }

    fn _bvc(self: *CPU, mode: AddressingMode) void {
        const address: u16 = self.getOperandAddress(mode);
        if (self.getFlag(StatusFlag.V) == 0) {
            self.program_counter = address;
        }
    }

    fn _bvs(self: *CPU, mode: AddressingMode) void {
        const address: u16 = self.getOperandAddress(mode);
        if (self.getFlag(StatusFlag.V) == 1) {
            self.program_counter = address;
        }
    }

    fn _clc(self: *CPU) void {
        self.setFlag(StatusFlag.C, false);
    }

    fn _cld(self: *CPU) void {
        self.setFlag(StatusFlag.D, false);
    }

    fn _cli(self: *CPU) void {
        self.setFlag(StatusFlag.I, false);
    }

    fn _clv(self: *CPU) void {
        self.setFlag(StatusFlag.V, false);
    }

    fn _cmp(self: *CPU, mode: AddressingMode) void {
        const address: u16 = self.getOperandAddress(mode);
        const fetched = self.bus.read8(address);

        const diff = self.register_a -% fetched;

        self.setFlag(StatusFlag.C, self.register_a >= fetched);
        self.updateZeroAndNegativeFlag(diff);
    }

    fn _cpx(self: *CPU, mode: AddressingMode) void {
        const address: u16 = self.getOperandAddress(mode);
        const fetched = self.bus.read8(address);

        const diff = self.register_x -% fetched;

        self.setFlag(StatusFlag.C, self.register_x >= fetched);
        self.updateZeroAndNegativeFlag(diff);
    }

    fn _cpy(self: *CPU, mode: AddressingMode) void {
        const address: u16 = self.getOperandAddress(mode);
        const fetched = self.bus.read8(address);

        const diff = self.register_y -% fetched;

        self.setFlag(StatusFlag.C, self.register_y >= fetched);
        self.updateZeroAndNegativeFlag(diff);
    }

    fn _dec(self: *CPU, mode: AddressingMode) void {
        const address: u16 = self.getOperandAddress(mode);
        const fetched = self.bus.read8(address) -% 1;

        self.bus.write8(address, fetched);
        self.updateZeroAndNegativeFlag(fetched);
    }

    fn _dex(self: *CPU) void {
        self.register_x -%= 1;
        self.updateZeroAndNegativeFlag(self.register_x);
    }

    fn _dey(self: *CPU) void {
        self.register_y -%= 1;
        self.updateZeroAndNegativeFlag(self.register_y);
    }

    fn _eor(self: *CPU, mode: AddressingMode) void {
        const address: u16 = self.getOperandAddress(mode);
        self.register_a ^= self.bus.read8(address);

        self.updateZeroAndNegativeFlag(self.register_a);
    }

    fn _inc(self: *CPU, mode: AddressingMode) void {
        const address: u16 = self.getOperandAddress(mode);
        const fetched = self.bus.read8(address) +% 1;

        self.bus.write8(address, fetched);
        self.updateZeroAndNegativeFlag(fetched);
    }

    fn _inx(self: *CPU) void {
        self.register_x +%= 1;
        self.updateZeroAndNegativeFlag(self.register_x);
    }

    fn _iny(self: *CPU) void {
        self.register_y +%= 1;
        self.updateZeroAndNegativeFlag(self.register_y);
    }

    fn _jmp(self: *CPU, mode: AddressingMode) void {
        const address: u16 = self.getOperandAddress(mode);
        self.program_counter = address;
    }

    fn _jsr(self: *CPU, mode: AddressingMode) void {
        const address: u16 = self.getOperandAddress(mode);

        const hi: u8 = @intCast(u8, ((self.program_counter + 1) >> 8) & 0xFF);
        const lo: u8 = @intCast(u8, (self.program_counter + 1) & 0xFF);
        self.pushToStack(hi);
        self.pushToStack(lo);

        self.program_counter = address;
    }

    fn _lda(self: *CPU, mode: AddressingMode) void {
        const address: u16 = self.getOperandAddress(mode);
        self.register_a = self.bus.read8(address);

        self.updateZeroAndNegativeFlag(self.register_a);
    }

    fn _ldx(self: *CPU, mode: AddressingMode) void {
        const address: u16 = self.getOperandAddress(mode);
        self.register_x = self.bus.read8(address);

        self.updateZeroAndNegativeFlag(self.register_x);
    }

    fn _ldy(self: *CPU, mode: AddressingMode) void {
        const address: u16 = self.getOperandAddress(mode);
        self.register_y = self.bus.read8(address);

        self.updateZeroAndNegativeFlag(self.register_y);
    }

    fn _lsr(self: *CPU, mode: AddressingMode) void {
        if (mode == AddressingMode.Accumulator) {
            self.setFlag(StatusFlag.C, (self.register_a & 0x01) == 1);
            self.register_a >>= 1;
            self.updateZeroAndNegativeFlag(self.register_a);
        } else {
            const address: u16 = self.getOperandAddress(mode);
            var fetched: u8 = self.bus.read8(address);

            self.setFlag(StatusFlag.C, (fetched & 0x01) == 1);
            fetched >>= 1;
            self.updateZeroAndNegativeFlag(fetched);
            self.bus.write8(address, fetched);
        }
    }

    fn _ora(self: *CPU, mode: AddressingMode) void {
        const address: u16 = self.getOperandAddress(mode);
        self.register_a |= self.bus.read8(address);

        self.updateZeroAndNegativeFlag(self.register_a);
    }

    fn _pha(self: *CPU) void {
        self.pushToStack(self.register_a);
    }

    fn _php(self: *CPU) void {
        // the reason of why we need to make a copy and set B and U flags is here:
        // https://wiki.nesdev.com/w/index.php?title=Status_flags
        var status: u8 = self.status;
        status |= (1 << 4) | (1 << 5);
        self.pushToStack(status);
    }

    fn _pla(self: *CPU) void {
        self.register_a = self.popFromStack();
        self.updateZeroAndNegativeFlag(self.register_a);
    }

    fn _plp(self: *CPU) void {
        // the reason of why we need to remove B and insert U flags is here:
        // https://wiki.nesdev.com/w/index.php?title=Status_flags
        self.status = self.popFromStack();
        self.setFlag(StatusFlag.B, false);
        self.setFlag(StatusFlag.U, true);
    }

    fn _rol(self: *CPU, mode: AddressingMode) void {
        if (mode == AddressingMode.Accumulator) {
            var fetched: u8 = self.register_a;
            const old_carry_flag: u1 = self.getFlag(StatusFlag.C);

            if (fetched >> 7 == 1) {
                self.setFlag(StatusFlag.C, true);
            } else {
                self.setFlag(StatusFlag.C, false);
            }

            fetched <<= 1;

            if (old_carry_flag == 1) {
                fetched |= 1;
            }
            self.register_a = fetched;
            self.updateZeroAndNegativeFlag(fetched);
        } else {
            const address: u16 = self.getOperandAddress(mode);
            var fetched: u8 = self.bus.read8(address);
            const old_carry_flag: u1 = self.getFlag(StatusFlag.C);

            if (fetched >> 7 == 1) {
                self.setFlag(StatusFlag.C, true);
            } else {
                self.setFlag(StatusFlag.C, false);
            }

            fetched <<= 1;

            if (old_carry_flag == 1) {
                fetched |= 1;
            }
            self.bus.write8(address, fetched);
            self.updateZeroAndNegativeFlag(fetched);
        }
    }

    fn _ror(self: *CPU, mode: AddressingMode) void {
        if (mode == AddressingMode.Accumulator) {
            var fetched: u8 = self.register_a;
            const old_carry_flag: u1 = self.getFlag(StatusFlag.C);

            if (fetched & 1 == 1) {
                self.setFlag(StatusFlag.C, true);
            } else {
                self.setFlag(StatusFlag.C, false);
            }

            fetched >>= 1;

            if (old_carry_flag == 1) {
                fetched |= 0b10000000;
            }
            self.register_a = fetched;
            self.updateZeroAndNegativeFlag(fetched);
        } else {
            const address: u16 = self.getOperandAddress(mode);
            var fetched: u8 = self.bus.read8(address);
            const old_carry_flag: u1 = self.getFlag(StatusFlag.C);

            if (fetched & 1 == 1) {
                self.setFlag(StatusFlag.C, true);
            } else {
                self.setFlag(StatusFlag.C, false);
            }

            fetched >>= 1;

            if (old_carry_flag == 1) {
                fetched |= 0b10000000;
            }
            self.bus.write8(address, fetched);
            self.updateZeroAndNegativeFlag(fetched);
        }
    }

    fn _rti(self: *CPU) void {
        self.status = self.popFromStack();

        const lo: u8 = self.popFromStack();
        const hi: u8 = self.popFromStack();

        self.setFlag(StatusFlag.B, false);
        self.setFlag(StatusFlag.U, true);

        self.program_counter = (@intCast(u16, hi) << 8) | (@intCast(u16, lo));
    }

    fn _rts(self: *CPU) void {
        const lo: u8 = self.popFromStack();
        const hi: u8 = self.popFromStack();

        self.program_counter = ((@intCast(u16, hi) << 8) | (@intCast(u16, lo))) + 1;
    }

    fn _sbc(self: *CPU, mode: AddressingMode) void {
        const address: u16 = self.getOperandAddress(mode);
        const fetched: u16 = @intCast(u16, self.bus.read8(address)) ^ 0x00FF;

        const result: u16 = @intCast(u16, self.register_a) + fetched + @intCast(u16, self.getFlag(StatusFlag.C));

        self.setFlag(StatusFlag.C, result > 0xFF);
        self.setFlag(StatusFlag.V, (~(@intCast(u16, self.register_a) ^ fetched) & (@intCast(u16, self.register_a) ^ result)) & 0x0080 != 0);
        self.updateZeroAndNegativeFlag(@intCast(u8, result & 0x00FF));

        self.register_a = @intCast(u8, result & 0x00FF);
    }

    fn _sec(self: *CPU) void {
        self.setFlag(StatusFlag.C, true);
    }

    fn _sed(self: *CPU) void {
        self.setFlag(StatusFlag.D, true);
    }

    fn _sei(self: *CPU) void {
        self.setFlag(StatusFlag.I, true);
    }

    fn _sta(self: *CPU, mode: AddressingMode) void {
        const address: u16 = self.getOperandAddress(mode);
        self.bus.write8(address, self.register_a);
    }

    fn _stx(self: *CPU, mode: AddressingMode) void {
        const address: u16 = self.getOperandAddress(mode);
        self.bus.write8(address, self.register_x);
    }

    fn _sty(self: *CPU, mode: AddressingMode) void {
        const address: u16 = self.getOperandAddress(mode);
        self.bus.write8(address, self.register_y);
    }

    fn _tax(self: *CPU) void {
        self.register_x = self.register_a;
        self.updateZeroAndNegativeFlag(self.register_x);
    }

    fn _tay(self: *CPU) void {
        self.register_y = self.register_a;
        self.updateZeroAndNegativeFlag(self.register_y);
    }

    fn _tsx(self: *CPU) void {
        self.register_x = self.stack_pointer;
        self.updateZeroAndNegativeFlag(self.register_x);
    }

    fn _txa(self: *CPU) void {
        self.register_a = self.register_x;
        self.updateZeroAndNegativeFlag(self.register_a);
    }

    fn _txs(self: *CPU) void {
        self.stack_pointer = self.register_x;
    }

    fn _tya(self: *CPU) void {
        self.register_a = self.register_y;
        self.updateZeroAndNegativeFlag(self.register_a);
    }
};
