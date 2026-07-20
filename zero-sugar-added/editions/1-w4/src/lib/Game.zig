const Game = @This();

// TODO: Dont repeat this everywhere
const tile_size = 16;

const diag_multiplier: @Vector(2, f16) = @splat(0.7);

state: State,
input: Input,
level: Level,
player: Player,

pub fn init(game: *Game) void {
    game.* = .{
        .state = .menu,
        .input = .empty,
        .level = levels.level_1,
        .player = .empty,
    };
}

pub fn tick(game: *Game) void {
    game.update();
    game.draw();
}

fn update(game: *Game) void {
    game.input.update(w4.gamepads[0]);
    switch (game.state) {
        .menu => {
            if (game.input.pressed.button_1) {
                game.state = .running;

                game.level = levels.level_1;
                game.player.xy = .{
                    game.level.start_col * tile_size,
                    game.level.start_row * tile_size,
                };
            }
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

fn draw(game: *const Game) void {
    switch (game.state) {
        .menu => {
            w4.text("Menu", 10, 10);
        },
        .running => {
            game.level.draw();
            game.player.draw();
        },
    }
}

const State = enum {
    menu,
    running,
};

const w4 = @import("w4");
const Input = @import("Input.zig");
const levels = @import("levels.zig");
const Level = @import("Level.zig");
const Player = @import("Player.zig");
