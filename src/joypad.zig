// https://www.nesdev.org/wiki/Controller_reading_code

pub const JoypadButton = enum(u8) {
    ButtonA = (1 << 0),
    ButtonB = (1 << 1),
    Select = (1 << 2),
    Start = (1 << 3),
    Up = (1 << 4),
    Down = (1 << 5),
    Left = (1 << 6),
    Right = (1 << 7),
};

pub const Joypad = struct {
    buttons: u8 = 0,
    button_index: u3 = 0,
    strobe: bool = false,

    pub fn write(self: *Joypad, data: u8) void {
        self.strobe = data & 1 == 1;
        if (self.strobe) {
            self.button_index = 0;
        }
    }

    pub fn read(self: *Joypad) u8 {
        const response = (self.buttons >> self.button_index) & 1;
        if (!self.strobe) {
            self.button_index +%= 1;
        }
        return response;
    }
};
