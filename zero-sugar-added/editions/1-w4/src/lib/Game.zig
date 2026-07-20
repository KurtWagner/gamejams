const Game = @This();

pub fn init(game: *Game) void {
    game.* = .{};
}

pub fn tick(game: *Game) void {
    game.update();
    game.draw();
}

fn update(game: *Game) void {
    _ = game;
}

fn draw(game: *const Game) void {
    _ = game;

    w4.DRAW_COLORS.* = 2;
    w4.text("Hello from Zig!", 10, 10);

    const gamepad = w4.GAMEPAD1.*;
    if (gamepad & w4.BUTTON_1 != 0) {
        w4.DRAW_COLORS.* = 4;
    }

    w4.text("Press X to blink", 16, 90);
}

const w4 = @import("w4");
