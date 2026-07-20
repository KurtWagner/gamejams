const Player = @This();

const tile_size = 16;

xy: @Vector(2, i16),

pub const empty: Player = .{
    .xy = .{ 0, 0 },
};

pub fn draw(player: Player) void {
    w4.oval(player.xy[0], player.xy[1], 8, 8);
}

const w4 = @import("w4");
