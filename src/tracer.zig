const CPU = @import("cpu.zig").CPU;
const OpcodesAPI = @import("opcodes.zig");
const Opcode = OpcodesAPI.Opcode;
const AddressingMode = OpcodesAPI.AddressingMode;

// for debug log printed to stdout
const std = @import("std");
const stdout = std.io.getStdOut().writer();

var cycles: u32 = 7;

pub fn trace(cpu: *CPU) void {
    const value: u8 = cpu.bus.read8(cpu.program_counter);
    const opcode: ?Opcode = cpu.opcodes.get(value);

    // var index: u8 = 0;
    const begin = cpu.program_counter;
    // var hex_dump = [_]u8{};
    // hex_dump[index] = code;

    cycles += opcode.?.cycles;

    cpu.program_counter += 1;

    var mem_address: u16 = 0;
    var stored_value: u8 = 0;
    switch (opcode.?.addressing_mode) {
        AddressingMode.Immediate => {},
        else => {
            mem_address = cpu.getOperandAddress(opcode.?.addressing_mode);
            stored_value = cpu.bus.read8(mem_address);
        },
    }

    switch (opcode.?.length) {
        1 => {},
        2 => {
            const address: u8 = cpu.bus.read8(begin + 1);
            //hex_dump.push(address);
        },
        3 => {
            //
        },
        else => {},
    }

    cpu.program_counter -= 1;

    stdout.print("{X}  {X}  {X}  {d}\n", .{ begin, value, stored_value, cycles }) catch unreachable;
}
