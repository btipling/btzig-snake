const game = @import("game/start.zig");

pub fn main() !void {
    try game.start();
}
