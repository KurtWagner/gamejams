const Player = @This();

const tile_size = 16;

xy: @Vector(2, f16),
size: @Vector(2, u8),
speed: @Vector(2, f16),

pub const empty: Player = .{
    .xy = @splat(0),
    .speed = @splat(5),
    .size = @splat(8),
};

pub fn draw(player: Player) void {
    w4.oval(
        @floor(player.xy[0]),
        @floor(player.xy[1]),
        player.size[0],
        player.size[1],
    );
}

const w4 = @import("w4");
