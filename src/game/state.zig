const std = @import("std");
const gl = @import("zopengl");
const grid = @import("grid.zig");

pub const coordinate = struct {
    x: gl.Float,
    y: gl.Float,
};

pub const State = struct {
    score: u32,
    speed: gl.Float,
    foodX: gl.Float,
    foodY: gl.Float,
    grid: grid.Grid,
    segments: std.ArrayList(coordinate),

    pub fn init(gameGrid: grid.Grid, initialSpeed: gl.Float, startX: gl.Float, startY: gl.Float, allocator: std.mem.Allocator) !State {
        var segments = std.ArrayList(coordinate).init(allocator);
        try segments.append(coordinate{ .x = startX, .y = startY });
        return State{
            .score = 0,
            .speed = initialSpeed,
            .foodX = 0.0,
            .foodY = 0.0,
            .grid = gameGrid,
            .segments = segments,
        };
    }

    pub fn getHeadPosition(self: *State) coordinate {
        return self.segments.items[0];
    }

    pub fn generateFoodPosition(self: *State) void {
        var foodPos = self.grid.randomGridPosition(self.score);
        self.foodX = foodPos[0];
        self.foodY = foodPos[1];
    }

    pub fn updateHeadPosition(self: *State, x: gl.Float, y: gl.Float) !void {
        var newX = self.grid.constrainGridPosition(x);
        var newY = self.grid.constrainGridPosition(y);
        var addone = false;
        if (newX == self.foodX and newY == self.foodY) {
            const newScore = self.score + 1;
            self.score = newScore;
            State.generateFoodPosition(self);
            std.debug.print("Score: {d}\n", .{newScore});
            addone = true;
        }
        var prevX: gl.Float = 0.0;
        var prevY: gl.Float = 0.0;
        for (self.segments.items, 0..) |coord, i| {
            prevX = coord.x;
            prevY = coord.y;
            self.segments.items[i] = coordinate{ .x = newX, .y = newY };
            newX = prevX;
            newY = prevY;
        }
        if (addone) {
            try self.segments.append(coordinate{ .x = prevX, .y = prevY });
        }
    }

    pub fn moveLeft(self: *State) !void {
        const head = self.getHeadPosition();
        try self.updateHeadPosition(head.x - self.speed, head.y);
    }

    pub fn moveRight(self: *State) !void {
        const head = self.getHeadPosition();
        try self.updateHeadPosition(head.x + self.speed, head.y);
    }

    pub fn moveUp(self: *State) !void {
        const head = self.getHeadPosition();
        try self.updateHeadPosition(head.x, head.y - self.speed);
    }

    pub fn moveDown(self: *State) !void {
        const head = self.getHeadPosition();
        try self.updateHeadPosition(head.x, head.y + self.speed);
    }
};
