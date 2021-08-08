const CPU = @import("cpu.zig").CPU;
const OpcodesAPI = @import("opcodes.zig");
const Opcode = OpcodesAPI.Opcode;
const AddressingMode = OpcodesAPI.AddressingMode;

const std = @import("std");
const fmt = @import("std").fmt;
const stdout = std.io.getStdOut().writer();

// I don't know, but initial cycles is 7
var cycles: u32 = 7;

// buffer for fmt
var buffer = [_]u8{undefined} ** 32;

pub fn trace(cpu: *CPU) void {
    const value: u8 = cpu.bus.read8(cpu.program_counter);
    const opcode: ?Opcode = cpu.opcodes.get(value);

    if (opcode == null) {
        // we print error in CPU, just return here
        return;
    }

    // copy program counter for later usage
    const begin_pc = cpu.program_counter;

    cycles += opcode.?.cycles;

    var mem_address: u16 = 0;
    var mem_hi: u8 = 0;
    var mem_lo: u8 = 0;
    var stored_value: u8 = 0;
    switch (opcode.?.addressing_mode) {
        AddressingMode.Immediate, AddressingMode.Relative => {
            mem_address = cpu.bus.read8(begin_pc + 1);
        },
        else => {
            // this is a bit hacky, but my implementation of getOperandAddress uses PC from CPU, so for the trace
            // I need to increment it before the usage and decrement after
            cpu.program_counter += 1;
            mem_address = cpu.getOperandAddress(opcode.?.addressing_mode);
            cpu.program_counter -= 1;

            stored_value = cpu.bus.read8(mem_address);

            // for the easy output split memory for hi and lo
            mem_hi = @intCast(u8, mem_address >> 8);
            mem_lo = @intCast(u8, mem_address & 0xFF);
        },
    }

    var address_hi: u8 = 0;
    var address_lo: u8 = 0;
    const tmp: []const u8 = switch (opcode.?.length) {
        1 => block: {
            const tmp: []const u8 = switch (value) {
                0x0A, 0x2A, 0x4A, 0x6A => "A ",
                else => "",
            };
            break :block tmp;
        },
        2 => block: {
            const address: u8 = cpu.bus.read8(begin_pc + 1);

            const tmp: []const u8 = switch (opcode.?.addressing_mode) {
                AddressingMode.Immediate => fmt.bufPrint(&buffer, "#${X:0>2}", .{address}) catch unreachable,

                AddressingMode.ZeroPage => fmt.bufPrint(&buffer, "${X:0>2} = {X:0>2}", .{ mem_address, stored_value }) catch unreachable,

                AddressingMode.ZeroPageX => fmt.bufPrint(&buffer, "${X:0>2},X @ {X:0>2} = {X:0>2}", .{ address, mem_address, stored_value }) catch unreachable,

                AddressingMode.ZeroPageY => fmt.bufPrint(&buffer, "${X:0>2},Y @ {X:0>2} = {X:0>2}", .{ address, mem_address, stored_value }) catch unreachable,

                AddressingMode.Relative, AddressingMode.Indirect, AddressingMode.Absolute => fmt.bufPrint(&buffer, "${X:0>4}", .{(begin_pc + 2) +% address}) catch unreachable,

                AddressingMode.IndirectX => fmt.bufPrint(&buffer, "(${X:0>2},X) @ {X:0>2} = {X:0>4} = {X:0>2}", .{ address, address +% cpu.register_x, mem_address, stored_value }) catch unreachable,

                AddressingMode.IndirectY => fmt.bufPrint(&buffer, "(${X:0>2}),Y = {X:0>4} @ {X:0>4} = {X:0>2}", .{ address, mem_address -% cpu.register_y, mem_address, stored_value }) catch unreachable,

                else => "",
            };
            break :block tmp;
        },
        3 => block: {
            address_lo = cpu.bus.read8(begin_pc + 1);
            address_hi = cpu.bus.read8(begin_pc + 2);

            const address: u16 = cpu.bus.read16(begin_pc + 1);

            const tmp: []const u8 = switch (opcode.?.addressing_mode) {
                AddressingMode.Absolute => block3: {
                    // const tmp1: []const u8 = switch (opcode.?.addressing_mode) {
                    const tmp1: []const u8 = switch (value) {
                        0x8E, 0xAE, 0xAD, 0x8D, 0xAC, 0x2C, 0x8C, 0x0D, 0x2D, 0x4D, 0x6D, 0xCD, 0xED, 0xEC, 0xCC, 0x4E, 0x0E, 0x2E, 0x6E, 0xEE, 0xCE => fmt.bufPrint(&buffer, "${X:0>4} = {X:0>2}", .{ mem_address, stored_value }) catch unreachable,
                        // AddressingMode.Absolute => fmt.bufPrint(&buffer, "${X:0>4} = {X:0>2}", .{ mem_address, stored_value }) catch unreachable,
                        else => fmt.bufPrint(&buffer, "${X:0>4}", .{mem_address}) catch unreachable,
                    };
                    break :block3 tmp1;
                },

                AddressingMode.AbsoluteX => fmt.bufPrint(&buffer, "${X:0>4},X @ {X:0>4} = {X:0>2}", .{ address, mem_address, stored_value }) catch unreachable,

                AddressingMode.AbsoluteY => fmt.bufPrint(&buffer, "${X:0>4},Y @ {X:0>4} = {X:0>2}", .{ address, mem_address, stored_value }) catch unreachable,

                AddressingMode.Indirect => block2: {
                    // JMP indirect
                    if (value == 0x6C) {
                        var jmp_address: u16 = undefined;
                        // hardware bug
                        if (address & 0x00FF == 0x00FF) {
                            const lo: u16 = cpu.bus.read8(address);
                            const hi: u16 = cpu.bus.read8(address & 0xFF00);
                            jmp_address = (hi << 8) | (lo);
                        } else {
                            jmp_address = @as(u16, mem_hi) << 8 | (mem_lo);
                        }
                        break :block2 fmt.bufPrint(&buffer, "(${X:0>4}) = {X:0>4}", .{ address, jmp_address }) catch unreachable;
                    } else {
                        break :block2 fmt.bufPrint(&buffer, "${X:0>4}", .{address}) catch unreachable;
                    }
                },

                else => "",
            };

            break :block tmp;
        },
        else => "",
    };

    stdout.print("{X:0>4}  {X:0>2} ", .{ begin_pc, value }) catch unreachable;

    if (opcode.?.length == 1) {
        stdout.print("       ", .{}) catch unreachable;
    } else if (opcode.?.length == 2) {
        switch (opcode.?.addressing_mode) {
            AddressingMode.IndirectX, AddressingMode.IndirectY, AddressingMode.ZeroPageX, AddressingMode.ZeroPageY => {
                const address: u8 = cpu.bus.read8(begin_pc + 1);
                stdout.print("{X:0>2}     ", .{address}) catch unreachable;
            },
            else => stdout.print("{X:0>2}     ", .{mem_address}) catch unreachable,
        }
    } else if (opcode.?.length == 3) {
        switch (opcode.?.addressing_mode) {
            AddressingMode.Indirect, AddressingMode.AbsoluteX, AddressingMode.AbsoluteY => stdout.print("{X:0>2} {X:0>2}  ", .{ address_lo, address_hi }) catch unreachable,
            else => stdout.print("{X:0>2} {X:0>2}  ", .{ mem_lo, mem_hi }) catch unreachable,
        }
    }

    // I think there is a bug, thats why I can't concatenate tmp normal way
    stdout.print("{s} {s}", .{ opcode.?.name, tmp }) catch unreachable;

    var i: usize = 28 - tmp.len;
    while (i > 0) : (i -= 1) {
        stdout.print(" ", .{}) catch unreachable;
    }

    stdout.print("A:{X:0>2} X:{X:0>2} Y:{X:0>2} P:{X:0>2} SP:{X:0>2} {X:0>2}\n", .{ cpu.register_a, cpu.register_x, cpu.register_y, cpu.status, cpu.stack_pointer, cpu.readFromStack() }) catch unreachable;
}
