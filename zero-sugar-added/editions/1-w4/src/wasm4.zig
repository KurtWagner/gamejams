// Copied from https://codeberg.org/zero-sugar-added/wasm4-template/src/commit/99efc9ea779a3ebedbec48abc9c0cb39a71e4cc7/LICENSE

// Copyright (c) Bruno Garcia et all
//
// Permission to use, copy, modify, and/or distribute this software for any
// purpose with or without fee is hereby granted, provided that the above
// copyright notice and this permission notice appear in all copies.
//
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
// REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND
// FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
// INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
// LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
// OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
// PERFORMANCE OF THIS SOFTWARE.

// WASM-4: https://wasm4.org/docs

/// The screen is a 160x160 square.
pub const screen_size_px: u32 = 160;

/// Text is drawn with an 8x8 bitmap font.
pub const font_size_px: u32 = 8;

/// Color palette referenced by the draw color state.
/// The first color is also used as the background clear color.
pub const palette: *[4]Color = @ptrFromInt(0x0004);

/// Draw functions reference the draw color state,
/// which itself references the palette state.
/// See `Draw`.
pub const draw: *Draw = @ptrFromInt(0x0014);

/// The latest gamepad button state is set before each `update()` call.
/// Up to four players are supported.
pub const gamepads: *const [4]Gamepad = @ptrFromInt(0x0016);

/// The latest mouse position is set before each `update()` call.
/// This value may lie outside of the game window.
pub const mouse_x: *const i16 = @ptrFromInt(0x001a);

/// The latest mouse position is set before each `update()` call.
/// This value may lie outside of the game window.
pub const mouse_y: *const i16 = @ptrFromInt(0x001c);

/// The latest mouse button state is set before each `update()` call.
pub const mouse: *const Mouse = @ptrFromInt(0x001e);

pub const system: *System = @ptrFromInt(0x001f);

pub const netplay: *const Netplay = @ptrFromInt(0x0020);

/// Row-major compressed 2-BPP pixel values (see `Draw`).
/// Each `u8` is the bitpacked values of four adjacent pixels,
/// where left-to-right is ordered LSB-to-MSB.
/// On little-endian systems (WebAssembly), this is effectively
/// a bitpacked length `160*160` array of `u2`/`Pixel`.
///
/// Functions are provided which copy sprites and shapes into the framebuffer,
/// but drawing can also be done directly by mutating this buffer.
pub const framebuffer: *[6400]u8 = @ptrFromInt(0x00a0);

pub const Color = packed struct(u32) {
    blue: u8,
    green: u8,
    red: u8,
    _: u8 = 0,

    pub fn fromInt(rgb: u24) Color {
        return @bitCast(@as(u32, rgb));
    }
};

/// A 2-BPP value to write to the framebuffer.
pub const Pixel = enum(u2) {
    /// Draw this pixel with the palette color set in `draw.color_1`.
    color_1 = 0,
    /// Draw this pixel with the palette color set in `draw.color_2`.
    color_2 = 1,
    /// Draw this pixel with the palette color set in `draw.color_3`.
    color_3 = 2,
    /// Draw this pixel with the palette color set in `draw.color_4`.
    color_4 = 3,

    /// A 1-BPP value, which sprites can be stored as and passed to `blit`.
    pub const Binary = enum(u1) {
        /// Draw this pixel with the palette color set in `draw.color_1`.
        color_1 = 0,
        /// Draw this pixel with the palette color set in `draw.color_2`.
        color_2 = 1,
    };
};

/// WASM-4 uses a double-indirect palette state (logical palette map/lookup).
///
/// Pixel values in the framebuffer, or passed to blit, are 1- or 2-bit logical/virtual colors.
/// These values first index this `PaletteColor` table,
/// selecting either `.color_1`, `.color_2`, `.color_3`, or `.color_4`.
/// Then, the active value of that draw color field indexes the `palette` itself
/// (or no color, if it was set to `.transparent`)
/// to finally select the color of the pixel.
///
/// This allows for sprites to be redrawn in clever ways with minimal changes to the draw state.
pub const Draw = packed struct(u16) {
    /// A pixel value of `0` picks whichever palette color is set here ("draw color #1").
    /// Draw functions use `.color_1` as the primary color.
    color_1: PaletteColor = .transparent,
    /// A pixel value of `1` picks whichever palette color is set here ("draw color #2").
    /// Draw functions use `.color_2` as the secondary color.
    color_2: PaletteColor = .transparent,
    /// A pixel value of `2` picks whichever palette color is set here ("draw color #3").
    color_3: PaletteColor = .transparent,
    /// A pixel value of `3` picks whichever palette color is set here ("draw color #4").
    color_4: PaletteColor = .transparent,

    /// An off-by-one index into the `palette`.
    pub const PaletteColor = enum(u4) {
        transparent = 0,
        /// The color at `palette[0]` ("palette color #1").
        palette_1 = 1,
        /// The color at `palette[1]` ("palette color #2").
        palette_2 = 2,
        /// The color at `palette[2]` ("palette color #3").
        palette_3 = 3,
        /// The color at `palette[3]` ("palette color #4").
        palette_4 = 4,
    };
};

/// `true` if the button is currently held.
pub const Gamepad = packed struct(u8) {
    /// X
    button_1: bool,
    /// Z
    button_2: bool,
    _: u2 = 0,
    /// D-pad left
    button_left: bool,
    /// D-pad right
    button_right: bool,
    /// D-pad up
    button_up: bool,
    /// D-pad down
    button_down: bool,
};

/// `true` if the button is currently held.
pub const Mouse = packed struct(u8) {
    button_left: bool,
    button_right: bool,
    button_middle: bool,
    _: u5 = 0,
};

pub const System = packed struct(u8) {
    /// Prevent clearing the framebuffer between frames.
    /// This value is initialized to `false`.
    preserve_framebuffer: bool = false,
    /// Hide the gamepad UI overlay on mobile.
    /// This value is initialized to `false`.
    hide_gamepad_overlay: bool = false,
    _: u6 = 0,
};

/// Multiplayer state.
pub const Netplay = packed struct(u8) {
    /// Local player index (0 to 3).
    player: u2,
    /// Whether netplay is currently active.
    active: bool,
    _: u5 = 0,
};

/// Copies pixels to the framebuffer, with the current `draw_colors` and `palette`.
/// If `options.format == .bpp_1`, reads one bit per pixel starting from `sprite`.
/// If `options.format == .bpp_2`, reads two bits per pixel.
pub extern fn blit(
    sprite: [*]const u8,
    x: i32,
    y: i32,
    width: u32,
    height: u32,
    options: BlitOptions,
) void;

/// Copies the subregion of a larger sprite to the framebuffer,
/// where `stride` is the width of the entire sprite,
/// and `src_x` and `src_y` are the source position within the sprite.
///
/// See `blit`.
pub extern fn blitSub(
    sprite: [*]const u8,
    x: i32,
    y: i32,
    width: u32,
    height: u32,
    src_x: u32,
    src_y: u32,
    stride: u32,
    options: BlitOptions,
) void;

pub const PixelFormat = enum(u1) {
    bpp_1 = 0,
    bpp_2 = 1,
};

pub const BlitOptions = packed struct(u32) {
    format: PixelFormat = .bpp_1,
    /// Flip the sprite horizontally
    flip_x: bool = false,
    /// Flip the sprite vertically
    flip_y: bool = false,
    /// Rotate the sprite 90 degrees anticlockwise
    rotate: bool = false,
    _: u28 = 0,
};

/// Draws a line between `(x1, y1)` and `(x2, y2)` with draw color #1.
pub extern fn line(x1: i32, y1: i32, x2: i32, y2: i32) void;

/// Draws a horizontal line between `(x, y)` and `(x + len - 1, y)` with draw color #1.
pub extern fn hline(x: i32, y: i32, len: u32) void;

/// Draws a vertical line between `(x, y)` and `(x, y + len - 1)` with draw color #1.
pub extern fn vline(x: i32, y: i32, len: u32) void;

/// Draws an oval (or circle) with draw color #1 as the fill and draw color #2 as the outline.
pub extern fn oval(x: i32, y: i32, width: u32, height: u32) void;

/// Draws a rectangle with draw color #1 as the fill and draw color #2 as the outline.
pub extern fn rect(x: i32, y: i32, width: u32, height: u32) void;

extern fn textUtf8(str: [*]const u8, len: usize, x: i32, y: i32) void;

/// Draws UTF-8-encoded text with the built-in 8x8 font.
/// The string may contain newline characters.
/// Draw color #1 is used as the text color,
/// and draw color #2 is used as the background color.
pub fn text(str: []const u8, x: i32, y: i32) void {
    textUtf8(str.ptr, str.len, x, y);
}

/// Plays a sound tone.
pub extern fn tone(frequency: Tone, duration: Adsr, volume: Volume, options: ToneOptions) void;

pub fn tonePure(hertz: u16, duration: Adsr, volume: Volume, options: ToneOptions.Simple) void {
    tone(.{ .pitch = .{ .hertz = hertz } }, duration, volume, .fromSimple(options, .hertz));
}

pub fn toneSlide(start_hertz: u16, end_hertz: u16, duration: Adsr, volume: Volume, options: ToneOptions.Simple) void {
    tone(
        .{ .pitch = .{ .hertz = start_hertz }, .slide = .{ .hertz = end_hertz } },
        duration,
        volume,
        .fromSimple(options, .hertz),
    );
}

pub fn toneNote(midi: u8, bend_factor: u8, duration: Adsr, volume: Volume, options: ToneOptions.Simple) void {
    tone(
        .{ .pitch = .{ .midi = .{ .note = midi, .bend = bend_factor } } },
        duration,
        volume,
        .fromSimple(options, .midi),
    );
}

pub const Tone = packed struct(u32) {
    pitch: Pitch,
    /// If nonzero, the frequency linearly ramps from `tone` to `slide`
    slide: Pitch = @bitCast(@as(u16, 0)),
};

pub const Pitch = packed union(u16) {
    /// Pass `options.pitch_mode == .hertz` to interpret `Pitch`s as this field
    hertz: u16,
    /// Pass `options.pitch_mode == .midi` to interpret `Pitch`s as this field
    midi: Midi,

    pub const Mode = enum(u1) {
        hertz = 0,
        midi = 1,
    };
};

pub const Midi = packed struct(u16) {
    /// Note number in the MIDI specification, e.g.
    /// C4 == 60, A4 == 69
    note: u8,
    /// Raise the pitch towards the next semitone,
    /// by a factor of `bend / 256`.
    bend: u8 = 0,
};

pub const Adsr = packed struct(u32) {
    /// Sustain time in frames (1/60 second)
    sustain: u8,
    /// Release time in frames (1/60 second)
    release: u8 = 0,
    /// Decay time in frames (1/60 second)
    decay: u8 = 0,
    /// Attack time in frames (1/60 second)
    attack: u8 = 0,

    /// Simple, rectangular on-off envelope
    pub fn gated(frames: u8) Adsr {
        return .{ .sustain = frames };
    }
};

/// The tone volume starts at zero,
/// rises to `peak` over the attack time,
/// lowers to `sustain` over the decay time,
/// holds at `sustain` over the sustain time,
/// and lowers to zero over the release time.
pub const Volume = packed struct(u32) {
    /// Volume used for the sustain duration. 0-100.
    sustain: u8,
    /// Peak volume reached over the attack time.
    /// If zero, defaults to `100`.
    peak: u8 = 0,
    _: u16 = 0,

    pub fn flat(percent: u8) Volume {
        return .{ .sustain = percent };
    }
};

pub const ToneOptions = packed struct(u32) {
    channel: Channel = .pulse_1,
    duty_cycle: DutyCycle = .eighth,
    pan: Pan = .center,
    pitch_mode: Pitch.Mode = .hertz,
    _: u25 = 0,

    pub const Simple = packed struct(u6) {
        channel: Channel = .pulse_1,
        duty_cycle: DutyCycle = .eighth,
        pan: Pan = .center,
    };

    pub fn fromSimple(simple: Simple, pitch_mode: Pitch.Mode) ToneOptions {
        return .{
            .channel = simple.channel,
            .duty_cycle = simple.duty_cycle,
            .pan = simple.pan,
            .pitch_mode = pitch_mode,
        };
    }
};

pub const Channel = enum(u2) {
    pulse_1 = 0,
    pulse_2 = 1,
    triangle = 2,
    noise = 3,
};

/// The [duty cycle](https://en.wikipedia.org/wiki/Duty_cycle)
/// is the ratio between the pulse duration and the pulse width.
pub const DutyCycle = enum(u2) {
    /// 12.5%
    eighth = 0,
    /// 25%
    quarter = 1,
    /// 50%
    half = 2,
    /// 75%
    three_fourth = 3,
};

pub const Pan = enum(u2) {
    center = 0,
    left = 1,
    right = 2,
};

// All disk read/write functions copy to/from the beginning of persistent storage.
// There is no indexed read/write functionality.

/// The game cartridge has 1024 bytes of persistent storage.
pub const disk_capacity = 1024;

/// Reads up to `size` bytes from persistent storage into `dest`.
/// Returns the number of bytes read, which may be less than `size`.
pub extern fn diskr(dest: [*]u8, size: u32) u32;

/// Copies as much of the contents of persistent storage as can fit into the `buffer`,
/// returning the result.
pub fn diskRead(buffer: []u8) []u8 {
    const size = diskr(buffer.ptr, buffer.len);
    return buffer[0..size];
}

/// Writes up to `size` bytes from `src` into persistent storage,
/// overwriting previous data.
/// Returns the number of bytes read, which may be less than `size`.
pub extern fn diskw(src: [*]const u8, size: u32) u32;

/// Copies as much of the `buffer` as can fit into persistent storage,
/// returning the number of bytes copied.
/// Overwrites previous data.
pub fn diskWrite(buffer: []const u8) usize {
    const size = diskw(buffer.ptr, buffer.len);
    return size;
}

/// Copies the `buffer` into persistent storage,
/// returning `error.NoSpace` if the contents cannot fit.
/// Overwrites previous data.
pub fn diskWriteBounded(buffer: []const u8) (error{NoSpace})!void {
    const size = diskw(buffer.ptr, buffer.len);
    if (size < buffer.len) return error.NoSpace;
}

/// Copies the `buffer` into persistent storage,
/// asserting it will fit.
/// Overwrites previous data.
pub fn diskWriteAssertBounded(buffer: []const u8) void {
    const size = diskw(buffer.ptr, buffer.len);
    if (size < buffer.len) unreachable;
}

/// Prints a message to the debug console.
pub fn trace(x: []const u8) void {
    traceUtf8(x.ptr, x.len);
}
extern fn traceUtf8(ptr: [*]const u8, len: usize) void;
