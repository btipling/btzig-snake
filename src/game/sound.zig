const zaudio = @import("zaudio");
const std = @import("std");

const content_dir = "src/game/assets/audio/";

pub const Sound = struct {
    engine: *zaudio.Engine,
    startSound: ?*zaudio.Sound,
    moveSound: ?*zaudio.Sound,
    pauseSound: ?*zaudio.Sound,
    unPauseSound: ?*zaudio.Sound,
    foodSound1: ?*zaudio.Sound,
    foodSound2: ?*zaudio.Sound,
    foodSound3: ?*zaudio.Sound,
    gameOverSound: ?*zaudio.Sound,

    pub fn init(engine: *zaudio.Engine) Sound {
        return Sound{
            .engine = engine,
            .startSound = null,
            .moveSound = null,
            .pauseSound = null,
            .unPauseSound = null,
            .foodSound1 = null,
            .foodSound2 = null,
            .foodSound3 = null,
            .gameOverSound = null,
        };
    }

    pub fn destroy(self: *Sound) void {
        if (self.startSound) |sound| {
            sound.destroy();
        }
        if (self.moveSound) |sound| {
            sound.destroy();
        }
        if (self.pauseSound) |sound| {
            sound.destroy();
        }
        if (self.unPauseSound) |sound| {
            sound.destroy();
        }
        if (self.foodSound1) |sound| {
            sound.destroy();
        }
        if (self.foodSound2) |sound| {
            sound.destroy();
        }
        if (self.foodSound3) |sound| {
            sound.destroy();
        }
        if (self.gameOverSound) |sound| {
            sound.destroy();
        }
    }

    pub fn playStartSound(self: *Sound) !void {
        if (self.startSound == null) {
            self.startSound = try self.engine.createSoundFromFile(content_dir ++ "start.mp3", .{ .flags = .{ .stream = true } });
        }
        if (self.startSound) |sound| {
            try sound.start();
        }
    }

    pub fn playMoveSound(self: *Sound) !void {
        if (self.moveSound == null) {
            self.moveSound = try self.engine.createSoundFromFile(content_dir ++ "move.mp3", .{ .flags = .{ .stream = true } });
        }
        if (self.moveSound) |sound| {
            try sound.start();
        }
    }

    pub fn playPauseSound(self: *Sound) !void {
        if (self.pauseSound == null) {
            self.pauseSound = try self.engine.createSoundFromFile(content_dir ++ "pause.mp3", .{ .flags = .{ .stream = true } });
        }
        if (self.pauseSound) |sound| {
            try sound.start();
        }
    }

    pub fn playUnPauseSound(self: *Sound) !void {
        if (self.unPauseSound == null) {
            self.unPauseSound = try self.engine.createSoundFromFile(content_dir ++ "unpause.mp3", .{ .flags = .{ .stream = true } });
        }
        if (self.unPauseSound) |sound| {
            try sound.start();
        }
    }

    pub fn playFoodSound(self: *Sound, soundNo: u2) !void {
        switch (soundNo) {
            1 => {
                if (self.foodSound2 == null) {
                    self.foodSound2 = try self.engine.createSoundFromFile(content_dir ++ "food2.mp3", .{ .flags = .{ .stream = true } });
                }
                if (self.foodSound2) |sound| {
                    try sound.start();
                }
            },
            2 => {
                if (self.foodSound3 == null) {
                    self.foodSound3 = try self.engine.createSoundFromFile(content_dir ++ "food3.mp3", .{ .flags = .{ .stream = true } });
                }
                if (self.foodSound3) |sound| {
                    try sound.start();
                }
            },
            else => {
                if (self.foodSound1 == null) {
                    self.foodSound1 = try self.engine.createSoundFromFile(content_dir ++ "food1.mp3", .{ .flags = .{ .stream = true } });
                }
                if (self.foodSound1) |sound| {
                    try sound.start();
                }
            },
        }
    }

    pub fn playGameOverSound(self: *Sound) !void {
        if (self.gameOverSound == null) {
            self.gameOverSound = try self.engine.createSoundFromFile(content_dir ++ "game_over.mp3", .{ .flags = .{ .stream = true } });
        }
        if (self.gameOverSound) |sound| {
            try sound.start();
        }
    }
};
