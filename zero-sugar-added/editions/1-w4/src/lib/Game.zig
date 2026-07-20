const Game = @This();

state: State,
input: Input,
level: Level,

pub fn init(game: *Game) void {
    game.* = .{
        .state = .menu,
        .input = .empty,
        .level = levels.level_1,
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
            }
        },
        .running => {
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
