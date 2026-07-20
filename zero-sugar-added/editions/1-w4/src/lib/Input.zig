const Input = @This();
/// Is down in this tick
down: w4.Gamepad,
/// Pressed in this tick
pressed: w4.Gamepad,

pub const empty: Input = .{
    .down = @bitCast(@as(u8, 0)),
    .pressed = @bitCast(@as(u8, 0)),
};

pub fn update(input: *Input, current: w4.Gamepad) void {
    const previous_down = input.down;
    input.down = current;
    input.pressed = @bitCast(@as(u8, @bitCast(input.down)) & ~@as(u8, @bitCast(previous_down)));
}

const w4 = @import("w4");
