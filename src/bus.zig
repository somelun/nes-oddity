pub const Bus = struct {
    memory: *[64 * 1024]u8,

    pub fn init(memory: *[64 * 1024]u8) Bus {
        return Bus{
            .memory = memory,
        };
    }

    pub fn write(address: u16, data: u8) !void {
        if (address >= 0x0000 and address <= 0xFFFF) {
            .memory[address] = data;
        }
    }

    pub fn read(address: u16) u8 {
        if (address >= 0x0000 and address <= 0xFFFF) {
            return .memory[address];
        }
    }
};
