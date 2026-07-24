const Player = @This();

const tile_size = 16;

xy: @Vector(2, f16),
size: @Vector(2, u8),
speed: @Vector(2, f16),
direction: Direction,

pub const Direction = enum { up, right, down, left };

pub const empty: Player = .{
    .xy = @splat(0),
    .speed = @splat(8),
    .size = .{ 10, 8 },
    .direction = .up,
};

pub fn draw(player: Player) void {
    defer w4.draw.color_1 = .palette_1;
    defer w4.draw.color_2 = .palette_2;

    w4.draw.color_1 = .palette_3;
    w4.draw.color_2 = .palette_4;
    w4.oval(
        @floor(player.xy[0]),
        @floor(player.xy[1]),
        player.size[0],
        player.size[1],
    );

    w4.draw.color_1 = .palette_4;

    switch (player.direction) {
        .up => w4.vline(
            @floor(player.xy[0] + player.size[0] / 2),
            @floor(player.xy[1] + player.size[1] / 2),
            8,
        ),
        .right => w4.hline(
            @floor(player.xy[0] - player.size[0] / 2),
            @floor(player.xy[1] + player.size[1] / 2),
            8,
        ),
        .down => w4.vline(
            @floor(player.xy[0] + player.size[0] / 2),
            @floor(player.xy[1] - player.size[1] / 2),
            8,
        ),
        .left => w4.hline(
            @floor(player.xy[0] + player.size[0] / 2),
            @floor(player.xy[1] + player.size[1] / 2),
            8,
        ),
    }
}

const w4 = @import("w4");
