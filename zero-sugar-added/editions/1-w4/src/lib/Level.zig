const Level = @This();

// TODO: Dont repeat this everywhere
const tile_size = 16;
const tile_size_vec2: @Vector(2, f16) = @splat(tile_size);

const TileKind = union(enum) {
    wall,
    clean,
    dirty_light,
    dirty_medium,
    dirty_hectic,
};

start_col: u8,
start_row: u8,
tiles: [10][10]TileKind,

pub const empty: Level = .{
    .start_col = 0,
    .start_row = 0,
    .tiles = @splat(@splat(.wall)),
};

pub fn parse(comptime bytes: []const u8) Level {
    var level: Level = .empty;
    var has_start = false;
    var row: u8 = 0;
    while (row < 10) : (row += 1) {
        const start = row * 11;
        for (bytes[start .. start + 10], 0..) |c, col| {
            switch (c) {
                '|' => level.tiles[col][row] = .wall,
                '0' => level.tiles[col][row] = .clean,
                '1' => level.tiles[col][row] = .dirty_light,
                '2' => level.tiles[col][row] = .dirty_medium,
                '3' => level.tiles[col][row] = .dirty_hectic,
                'x' => {
                    level.tiles[col][row] = .clean;
                    level.start_col = @intCast(col);
                    level.start_row = @intCast(row);
                    has_start = true;
                },
                else => @compileError("Invalid character"),
            }
        }
    }
    if (!has_start)
        @compileError("Level missing start");

    return level;
}

pub fn draw(level: Level) void {
    var row: u8 = 0;
    while (row < level.tiles.len) : (row += 1) {
        var col: u8 = 0;
        while (col < 10) : (col += 1) {
            switch (level.tiles[col][row]) {
                .wall => drawTile(
                    .{ .col = 0, .row = 3 },
                    .{ .col = col, .row = row },
                ),
                .dirty_light => drawTile(
                    .{ .col = 0, .row = 0 },
                    .{ .col = col, .row = row },
                ),
                .dirty_medium => drawTile(
                    .{ .col = 0, .row = 1 },
                    .{ .col = col, .row = row },
                ),
                .dirty_hectic => drawTile(
                    .{ .col = 0, .row = 2 },
                    .{ .col = col, .row = row },
                ),
                else => {},
            }
        }
    }
}

const TilePos = struct {
    col: u8,
    row: u8,
};

fn drawTile(src: TilePos, dest: TilePos) void {
    w4.blitSub(
        &assets.tiles,
        dest.col * tile_size,
        dest.row * tile_size,
        tile_size,
        tile_size,
        src.col * tile_size,
        src.row * tile_size,
        assets.tiles_width,
        .{ .format = .bpp_2 },
    );
}

pub fn isCollision(level: Level, player: Player) bool {
    const player_top_left = player.xy;
    const player_bottom_right: @Vector(2, f16) = player.xy + player.size;

    // TODO: Just check surrounding tiles
    var row: u8 = 0;
    while (row < level.tiles.len) : (row += 1) {
        var col: u8 = 0;
        while (col < 10) : (col += 1) {
            if (level.tiles[col][row] == .wall) {
                const tile_top_left: @Vector(2, f16) = .{
                    col * tile_size,
                    row * tile_size,
                };
                const tile_bottom_right = tile_top_left + tile_size_vec2;

                const inside_x = (player_top_left[0] <= tile_bottom_right[0]) and (player_bottom_right[0] >= tile_top_left[0]);
                const inside_y = (player_top_left[1] <= tile_bottom_right[1]) and (player_bottom_right[1] >= tile_top_left[1]);

                if (inside_x and inside_y)
                    return true;
            }
        }
    }
    return false;
}

const std = @import("std");
const w4 = @import("w4");
const Player = @import("Player.zig");
const assets = @import("assets");
