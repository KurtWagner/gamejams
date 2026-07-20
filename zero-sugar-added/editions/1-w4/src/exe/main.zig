var game: game_lib.Game = undefined;

export fn start() void {
    game.init();
}

export fn update() void {
    game.tick();
}

const game_lib = @import("game");
