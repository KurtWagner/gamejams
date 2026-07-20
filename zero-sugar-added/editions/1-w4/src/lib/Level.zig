const Level = @This();

const tile_size = 16;

start_col: u4,
start_row: u4,
rows: [10]std.bit_set.Integer(10),

pub const empty: Level = .{
    .start_col = 0,
    .start_row = 0,
    .rows = @splat(.empty),
};

pub fn parse(comptime bytes: []const u8) Level {
    var level: Level = .empty;
    var has_start = false;
    var row: u16 = 0;
    while (row < 10) : (row += 1) {
        const start = row * 11;
        for (bytes[start .. start + 10], 0..) |c, col| {
            switch (c) {
                '|' => {},
                '0' => {
                    level.rows[row].set(col);
                },
                '1' => {
                    level.rows[row].set(col);
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
    var row: u16 = 0;
    while (row < level.rows.len) : (row += 1) {
        const cols = level.rows[row];
        var col: u16 = 0;
        while (col < 10) : (col += 1) {
            if (!cols.isSet(col)) {
                w4.rect(
                    col * tile_size,
                    row * tile_size,
                    tile_size,
                    tile_size,
                );
            }
        }
    }
}

const std = @import("std");
const w4 = @import("w4");
