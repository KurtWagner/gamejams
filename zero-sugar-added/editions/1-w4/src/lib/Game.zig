const Game = @This();

// TODO: Dont repeat this everywhere
const tile_size = 16;

const diag_multiplier: @Vector(2, f16) = @splat(0.7);

state: State,
input: Input,
level: Level,
player: Player,
frame: u16,

menu_cleaner_x_offset: u1 = 0,
menu_banner_y: i32 = 0,

pub fn init(game: *Game) void {
    game.* = .{
        .state = .reset,
        .input = .empty,
        .level = levels.level_1,
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
            game.frame = 0;
            game.menu_banner_y = -assets.banner_height;
            game.menu_cleaner_x_offset = 0;
            game.state = .menu;
        },
        .menu => {
            game.playMenuMusic();

            if (game.input.pressed.button_1) {
                game.state = .running;

                game.level = levels.level_1;
                game.player.xy = .{
                    game.level.start_col * tile_size,
                    game.level.start_row * tile_size,
                };
            }

            if (game.frame % 60 == 0)
                game.menu_cleaner_x_offset +%= 1;

            if (game.menu_banner_y < 10 and game.frame % 2 == 0)
                game.menu_banner_y += 1;
        },
        .running => {
            // TODO:  Fix diagonal speed
            var velocity: @Vector(2, f16) = .{ 0, 0 };
            if (game.input.down.button_left) {
                velocity[0] -= 0.2;
            } else if (game.input.down.button_right) {
                velocity[0] += 0.2;
            }
            if (game.input.down.button_up) {
                velocity[1] -= 0.2;
            } else if (game.input.down.button_down) {
                velocity[1] += 0.2;
            }

            if (velocity[0] != 0 and velocity[1] != 0)
                velocity *= diag_multiplier;

            const current = game.player.xy;

            game.player.xy += (velocity * game.player.speed);
            if (game.level.isCollision(game.player)) {
                game.player.xy = current;
            }

            if (game.input.pressed.button_1) {
                game.state = .menu;
            }
        },
    }
}

fn playMenuMusic(game: *const Game) void {
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
            game.level.draw();
            game.player.draw();
        },
        .reset => {},
    }
}

const State = enum {
    menu,
    running,
    reset,
};

const w4 = @import("w4");
const Input = @import("Input.zig");
const levels = @import("levels.zig");
const Level = @import("Level.zig");
const Player = @import("Player.zig");
const assets = @import("assets");
