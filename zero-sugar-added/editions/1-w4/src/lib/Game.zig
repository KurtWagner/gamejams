const Game = @This();

// TODO: Dont repeat this everywhere
const tile_size = 16;

const diag_multiplier: @Vector(2, f16) = @splat(0.7);

state: State,
input: Input,
level_index: LevelIndex,
player: Player,
frame: u16,

menu_cleaner_x_offset: u1 = 0,
menu_banner_y: i32 = 0,

/// Copy of the level for game mutation
active_level: ?Level = null,

/// Time remaining to complete the level. Remaining time from previous levels
/// accumulate.
remaining_time_seconds: f32 = 0,

pub fn init(game: *Game) void {
    game.* = .{
        .state = .reset,
        .input = .empty,
        .level_index = 0,
        .player = .empty,
        .frame = 0,
    };

    w4.palette.* = .{
        w4.Color.fromInt(0xe0f8cf),
        w4.Color.fromInt(0x86c06c),
        w4.Color.fromInt(0x306850),
        w4.Color.fromInt(0x071821),
    };

    w4.draw.* = .{
        .color_1 = .palette_1,
        .color_2 = .palette_2,
        .color_3 = .palette_3,
        .color_4 = .palette_4,
    };
}

pub fn tick(game: *Game) void {
    game.update();
    game.draw();
}

fn update(game: *Game) void {
    game.input.update(w4.gamepads[0]);
    game.frame +%= 1;

    switch (game.state) {
        .reset => {
            game.playMusic();
            game.frame = 0;
            game.menu_banner_y = -assets.banner_height;
            game.menu_cleaner_x_offset = 0;
            game.state = .menu;
        },
        .menu => {
            game.playMusic();

            if (game.input.pressed.button_1) {
                game.state = .{ .level_start = 0 };
            }

            if (game.frame % 60 == 0)
                game.menu_cleaner_x_offset +%= 1;

            if (game.menu_banner_y < 10 and game.frame % 2 == 0)
                game.menu_banner_y += 1;
        },
        .running => {
            game.playMusic();
            game.remaining_time_seconds -= 1.0 / 60.0;
            if (game.remaining_time_seconds <= 0) {
                game.state = .{
                    .game_over = .{
                        .max_level_reached = game.level_index + 1,
                        .total_tiles_cleaned = 0, // TODO: implemenmt this
                    },
                };
                return;
            }

            var velocity: @Vector(2, f16) = .{ 0, 0 };
            if (game.input.down.button_left) {
                velocity[0] -= 0.2;
                game.player.direction = .left;
            } else if (game.input.down.button_right) {
                velocity[0] += 0.2;
                game.player.direction = .right;
            }
            if (game.input.down.button_up) {
                velocity[1] -= 0.2;
                game.player.direction = .up;
            } else if (game.input.down.button_down) {
                velocity[1] += 0.2;
                game.player.direction = .down;
            }

            if (velocity[0] != 0 and velocity[1] != 0)
                velocity *= diag_multiplier;

            const current = game.player.xy;

            game.player.xy += (velocity * game.player.speed);
            switch (game.active_level.?.getCollision(game.player)) {
                // Get back there mate
                .wall => game.player.xy = current,
                // Good job cleaning this tile
                .enter_floor_tile => |pos| {
                    if (game.active_level.?.clean(pos)) {
                        w4.toneSlide(900, 240, .{
                            .sustain = 20,
                            .release = 20,
                        }, w4.Volume.flat(8), .{
                            .channel = .noise,
                        });
                    }

                    // TODO: clean but needs copy of dirt
                },
                .none => {},
            }

            if (game.active_level.?.isComplete()) {
                game.state = .level_complete;
            }
        },
        .level_start => |level_idx| {
            game.playMusic();
            game.level_index = level_idx;
            game.active_level = levels.all[game.level_index];
            game.remaining_time_seconds += game.active_level.?.allowed_seconds;
            game.player.xy = .{
                game.active_level.?.start_col * tile_size,
                game.active_level.?.start_row * tile_size,
            };
            game.state = .running;
        },
        .level_complete => {
            game.playMusic();
            if (game.input.pressed.button_1) {
                game.state = .{ .level_start = game.level_index + 1 };
            }
        },
        .game_over => {
            game.playGameOverMusicOnce();

            if (game.input.pressed.button_1) {
                game.state = .reset;
            }
        },
    }
}

fn playMusic(game: *const Game) void {
    const note_duration = w4.Adsr{
        .sustain = 6,
        .release = 3,
    };
    const note_volume = w4.Volume.flat(12);
    const bass_volume = w4.Volume.flat(28);

    switch (game.frame % 80) {
        10 => {
            w4.toneNote(48, 0, w4.Adsr.gated(8), bass_volume, .{
                .channel = .triangle,
            });
            w4.toneNote(60, 0, note_duration, note_volume, .{
                .channel = .pulse_1,
                .duty_cycle = .quarter,
            });
        },
        20 => {
            w4.toneNote(64, 0, note_duration, note_volume, .{
                .channel = .pulse_1,
                .duty_cycle = .quarter,
            });
        },
        40 => {
            w4.toneNote(55, 0, w4.Adsr.gated(8), bass_volume, .{
                .channel = .triangle,
            });
            w4.toneNote(64, 0, note_duration, note_volume, .{
                .channel = .pulse_1,
                .duty_cycle = .quarter,
            });
            w4.toneNote(72, 0, note_duration, note_volume, .{
                .channel = .pulse_1,
                .duty_cycle = .quarter,
            });
        },
        60 => {
            w4.toneNote(53, 0, w4.Adsr.gated(8), bass_volume, .{
                .channel = .triangle,
            });
            w4.toneNote(69, 0, note_duration, note_volume, .{
                .channel = .pulse_1,
                .duty_cycle = .quarter,
            });
        },
        else => {},
    }
}

fn playGameOverMusicOnce(game: *Game) void {
    std.debug.assert(game.state == .game_over);

    if (game.state.game_over.game_over_frame > 54) return;
    game.state.game_over.game_over_frame += 1;

    const melody_volume = w4.Volume.flat(16);
    const bass_volume = w4.Volume.flat(24);
    const melody_duration = w4.Adsr{
        .sustain = 14,
        .release = 8,
    };
    const bass_duration = w4.Adsr.gated(16);

    switch (game.state.game_over.game_over_frame) {
        0 => {
            w4.toneNote(67, 0, melody_duration, melody_volume, .{
                .channel = .pulse_1,
                .duty_cycle = .half,
            });
            w4.toneNote(43, 0, bass_duration, bass_volume, .{
                .channel = .triangle,
            });
        },
        18 => {
            w4.toneNote(66, 0, melody_duration, melody_volume, .{
                .channel = .pulse_1,
                .duty_cycle = .half,
            });
        },
        36 => {
            w4.toneNote(65, 0, melody_duration, melody_volume, .{
                .channel = .pulse_1,
                .duty_cycle = .half,
            });
            w4.toneNote(41, 0, bass_duration, bass_volume, .{
                .channel = .triangle,
            });
        },
        54 => {
            w4.toneNote(64, 0, .{
                .sustain = 28,
                .release = 18,
            }, melody_volume, .{
                .channel = .pulse_1,
                .duty_cycle = .half,
            });
            w4.toneNote(36, 0, .{
                .sustain = 28,
                .release = 18,
            }, bass_volume, .{
                .channel = .triangle,
            });
        },
        else => {},
    }
}

fn draw(game: *const Game) void {
    switch (game.state) {
        .menu => {
            w4.blit(
                &assets.landing_bg,
                0,
                0,
                assets.landing_bg_width,
                assets.landing_bg_height,
                .{ .format = .bpp_2 },
            );

            const x: i32 = 40;
            w4.blit(
                &assets.landing_cleaner,
                x + game.menu_cleaner_x_offset,
                70,
                assets.landing_cleaner_width,
                assets.landing_cleaner_height,
                .{ .format = .bpp_2 },
            );

            w4.blit(
                &assets.banner,
                0,
                game.menu_banner_y,
                assets.banner_width,
                assets.banner_height,
                .{ .format = .bpp_2 },
            );
        },
        .running => {
            game.active_level.?.draw();
            game.player.draw();

            var level_text: [10]u8 = undefined;
            const text = std.fmt.bufPrint(
                &level_text,
                "Level {d}",
                .{game.level_index + 1},
            ) catch unreachable;

            w4.draw.color_2 = .palette_4;
            defer w4.draw.color_2 = .palette_2;
            w4.text(text, 12, 4);

            const centiseconds: u32 = @intFromFloat(game.remaining_time_seconds * 100);
            var time_text: [8]u8 = undefined;
            const time = std.fmt.bufPrint(
                &time_text,
                "{d:0>2}:{d:0>2}.{d:0>2}",
                .{
                    (centiseconds / 6000) % 100,
                    (centiseconds / 100) % 60,
                    centiseconds % 100,
                },
            ) catch unreachable;

            w4.text(time, 83, 4);
        },
        .reset => {},
        .level_complete => {
            w4.draw.color_1 = .palette_4;
            w4.rect(0, 0, w4.screen_size_px, w4.screen_size_px);

            w4.draw.color_1 = .palette_1;
            w4.draw.color_2 = .palette_4;
            defer w4.draw.color_1 = .palette_1;
            defer w4.draw.color_2 = .palette_2;

            var level_text: [18]u8 = undefined;
            const level = std.fmt.bufPrint(
                &level_text,
                "Level {d} COMPLETED",
                .{game.level_index + 1},
            ) catch unreachable;

            const centiseconds: u32 = @intFromFloat(game.remaining_time_seconds * 100);
            var time_text: [11]u8 = undefined;
            const time = std.fmt.bufPrint(
                &time_text,
                "{d:0>2}:{d:0>2}.{d:0>2}",
                .{
                    (centiseconds / 6000) % 100,
                    (centiseconds / 100) % 60,
                    centiseconds % 100,
                },
            ) catch unreachable;

            w4.text(level, 12, 72);
            w4.draw.color_1 = .palette_2;
            w4.text(time, 45, 88);
        },
        .level_start => {},
        .game_over => |stats| {
            w4.draw.color_1 = .palette_4;
            w4.rect(0, 0, w4.screen_size_px, w4.screen_size_px);

            var level_text: [32]u8 = undefined;
            const level = std.fmt.bufPrint(
                &level_text,
                "Max Level {d}",
                .{stats.max_level_reached},
            ) catch unreachable;

            var tiles_text: [32]u8 = undefined;
            const tiles = std.fmt.bufPrint(
                &tiles_text,
                "Tiles Cleaned {d}",
                .{stats.total_tiles_cleaned},
            ) catch unreachable;

            w4.draw.color_1 = .palette_1;
            w4.draw.color_2 = .palette_4;

            // The game can be changed to not need these defers but its a jam so eh
            defer w4.draw.color_1 = .palette_1;
            defer w4.draw.color_2 = .palette_2;

            w4.text("GAME OVER", 43, 50);
            w4.draw.color_1 = .palette_2;

            w4.text(level, 38, 72);
            w4.text(tiles, 18, 88);
        },
    }
}

const State = union(enum) {
    menu,
    running,
    level_complete,
    reset,
    level_start: LevelIndex,
    game_over: struct {
        max_level_reached: u8,
        total_tiles_cleaned: u32,
        game_over_frame: u8 = 0,
    },
};

const w4 = @import("w4");
const Input = @import("Input.zig");
const levels = @import("levels.zig");
const LevelIndex = levels.LevelIndex;
const Level = @import("Level.zig");
const Player = @import("Player.zig");
const assets = @import("assets");
const std = @import("std");
