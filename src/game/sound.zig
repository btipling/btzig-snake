const zaudio = @import("zaudio");
const std = @import("std");

pub const Sound = struct {
    engine: *zaudio.Engine,
    startSound: ?*zaudio.Sound,

    pub fn init(engine: *zaudio.Engine) Sound {
        return Sound{
            .engine = engine,
            .startSound = null,
        };
    }

    pub fn destroy(self: *Sound) void {
        if (self.startSound) |sound| {
            sound.destroy();
        }
    }

    pub fn playStartSound(self: *Sound) !void {
        if (self.startSound == null) {
            std.debug.print("Loading start sound\n", .{});
            self.startSound = try self.engine.createSoundFromFile("src/game/assets/audio/start.mp3", .{ .flags = .{ .stream = true } });
        }
        if (self.startSound) |sound| {
            try sound.start();
        }
    }
};
