pub const all: [1]Level = .{
    Level.parse(
        \\||||||||||
        \\|--------|
        \\|22222213|
        \\|22233313|
        \\|1|||||33|
        \\||||---30|
        \\||||33332|
        \\||||x0110|
        \\|||||||33|
        \\||||||||||
    ),
};

pub const LevelIndex = u8;

const Level = @import("Level.zig");
