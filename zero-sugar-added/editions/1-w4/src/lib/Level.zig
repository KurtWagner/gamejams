const Level = @This();

// TODO: Dont repeat this everywhere
const tile_size = 16;
const tile_size_vec2: @Vector(2, f16) = @splat(tile_size);

/// Indicates wheter there's floor (true) or wall (false) in each quadrant from vertex
const Vertex = struct {
    top_left: bool = false,
    top_right: bool = false,
    bottom_left: bool = false,
    bottom_right: bool = false,

    const none: Vertex = .{};
};

const TileKind = enum {
    none,
    back_wall,
    wall,
    clean,
    dirty_light,
    dirty_medium,
    dirty_hectic,

    fn isWall(self: @This()) bool {
        return switch (self) {
            .none => false,
            .wall, .back_wall => true,
            .clean, .dirty_light, .dirty_medium, .dirty_hectic => false,
        };
    }

    fn isFloor(self: @This()) bool {
        return switch (self) {
            .none => false,
            .wall, .back_wall => false,
            .clean, .dirty_light, .dirty_medium, .dirty_hectic => true,
        };
    }
};

start_col: u8,
start_row: u8,
tiles: [10][10]TileKind,
vertices: [11][11]Vertex,

pub const empty: Level = .{
    .start_col = 0,
    .start_row = 0,
    .tiles = @splat(@splat(.wall)),
    .vertices = @splat(@splat(.none)),
};

pub fn parse(comptime bytes: []const u8) Level {
    var level: Level = .empty;
    var has_start = false;
    var row: u8 = 0;
    while (row < 10) : (row += 1) {
        const start = row * 11;
        for (bytes[start .. start + 10], 0..) |c, col| {
            switch (c) {
                '-' => level.tiles[col][row] = .back_wall,
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

    // TODO: Make iterator for this? Duplicated in draw or who really caresfor a jam.
    row = 0;
    while (row < level.tiles.len) : (row += 1) {
        var col: u8 = 0;
        while (col < 10) : (col += 1) {
            const kind = level.tiles[col][row];

            if (kind.isFloor()) {
                level.vertices[col][row].bottom_right = true;
                level.vertices[col + 1][row].bottom_left = true;
                level.vertices[col][row + 1].top_right = true;
                level.vertices[col + 1][row + 1].top_left = true;
            }
        }
    }

    return level;
}

pub fn draw(level: Level) void {
    var row: u8 = 0;
    while (row < level.tiles.len) : (row += 1) {
        var col: u8 = 0;
        while (col < 10) : (col += 1) {
            const pos: TilePos = .{ .col = col, .row = row };
            const kind = level.tiles[col][row];
            switch (kind) {
                .back_wall => {
                    drawTile(
                        .{ .col = 1, .row = 3 },
                        pos,
                    );
                },
                .wall => drawTile(
                    .{ .col = 0, .row = 3 },
                    pos,
                ),
                .dirty_light => drawTile(
                    .{ .col = 0, .row = 0 },
                    pos,
                ),
                .dirty_medium => drawTile(
                    .{ .col = 0, .row = 1 },
                    pos,
                ),
                .dirty_hectic => drawTile(
                    .{ .col = 0, .row = 2 },
                    pos,
                ),
                else => {},
            }

            if (kind.isWall()) {
                const x, const y = pos.toXy();

                const right = level.tileToRight(pos);
                const left = level.tileToLeft(pos);
                const top = level.tileToTop(pos);

                if (left.isFloor() or (left == .back_wall and kind == .wall)) {
                    drawSlice(
                        SliceWallEdge,
                        .{ .x = x, .y = y },
                        .{
                            .flip_x = true,
                        },
                    );
                }
                if (right.isFloor() or (right == .back_wall and kind == .wall)) {
                    drawSlice(
                        SliceWallEdge,
                        .{ .x = x + tile_size - SliceWallEdge.w, .y = y },
                        .{},
                    );
                }

                if (top.isFloor()) {
                    drawSlice(
                        SliceWallTopEdge,
                        .{ .x = x, .y = y },
                        .{},
                    );
                }
            }
        }
    }
}

fn tileToLeft(level: Level, src: TilePos) TileKind {
    if (src.col == 0) return .none;
    return level.tiles[src.col - 1][src.row];
}

fn tileToRight(level: Level, src: TilePos) TileKind {
    if (src.col == level.tiles.len - 1) return .none;
    return level.tiles[src.col + 1][src.row];
}

fn tileToBottom(level: Level, src: TilePos) TileKind {
    if (src.row == level.tiles[0].len - 1) return .none;
    return level.tiles[src.col][src.row + 1];
}

fn tileToTop(level: Level, src: TilePos) TileKind {
    if (src.row == 0) return .none;
    return level.tiles[src.col][src.row - 1];
}

const TilePos = struct {
    col: u8,
    row: u8,

    fn toXy(self: TilePos) struct { u8, u8 } {
        return .{
            self.col * tile_size,
            self.row * tile_size,
        };
    }
};

const Slice = struct {
    x: u8,
    y: u8,
    w: u8,
    h: u8,
};

const SliceWallEdge: Slice = .{
    .x = 40,
    .y = 48,
    .w = 4,
    .h = 16,
};

const SliceWallTopEdge: Slice = .{
    .x = 48,
    .y = 48,
    .w = 16,
    .h = 3,
};

const DrawSliceOptions = struct {
    flip_x: bool = false,
};

fn drawSlice(slice: Slice, dest: struct { x: i32, y: i32 }, options: DrawSliceOptions) void {
    w4.blitSub(
        &assets.tiles,
        dest.x,
        dest.y,
        slice.w,
        slice.h,
        slice.x,
        slice.y,
        assets.tiles_width,
        .{
            .format = .bpp_2,
            .flip_x = options.flip_x,
        },
    );
}

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
            if (level.tiles[col][row].isWall()) {
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
