# Zero Sugar Added (1st Edition)

More information about Zero Sugar Added edition can be found [here](https://codeberg.org/zero-sugar-added/jam/src/branch/main/editions/1-WASM-4.md).

## Full Steam (Clean) Ahead

### Theme

> Full Steam Ahead

### Story

Idea is that your job is to steam clean rooms but only have a limited time to
do them. You're allocated extra time for each dirty tile but your boss is an
asshole and doesn't care if the tile is lightly dirty (requires one pass) or epicly dirty (requires three passes).

### If I had more time

Would've been cool to try my hand at some angry boss pixel art and more animations and counters with companion sounds on the level complete pages (thinking like super mario land).

[Play in your browser](https://kurtwagner.github.io/gamejams/zero-sugar-added/editions/1-w4/)

<img src="screenshot_menu.png" alt="Zero Sugar Added menu" width="50%"><img src="screenshot_level.png" alt="Zero Sugar Added level" width="50%">

## Build and run

Using [Zig](https://ziglang.org/) (0.17.x) and [WASM-4](https://wasm4.org/). Run with:

```shell
zig build run
```

## Deploy to HTML

Build the standalone web page with:

```shell
zig build deploy
```
