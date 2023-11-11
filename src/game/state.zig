const std = @import("std");
const gl = @import("zopengl");
const grid = @import("grid.zig");

pub const coordinate = struct {
    x: gl.Float,
    y: gl.Float,
};

const Direction = enum(i32) {
    Left,
    Right,
    Up,
    Down,
};

pub const State = struct {
    score: u32,
    speed: gl.Float,
    delay: gl.Uint,
    paused: bool,
    direction: Direction,
    foodX: gl.Float,
    foodY: gl.Float,
    grid: grid.Grid,
    segments: std.ArrayList(coordinate),

    pub fn init(
        gameGrid: grid.Grid,
        initialSpeed: gl.Float,
        initialDelay: gl.Uint,
        startX: gl.Float,
        startY: gl.Float,
        allocator: std.mem.Allocator,
    ) !State {
        var segments = std.ArrayList(coordinate).init(allocator);
        try segments.append(coordinate{ .x = startX, .y = startY });
        return State{
            .score = 0,
            .speed = initialSpeed,
            .paused = false,
            .direction = Direction.Right,
            .delay = initialDelay,
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
            addone = true;
            // decrease delay exponentially
            self.delay = @as(gl.Uint, @intFromFloat(@as(gl.Float, @floatFromInt(self.delay)) * 0.9));
            std.debug.print("Score: {d} Delay: {d}\n", .{ newScore, self.delay });
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

    // pause

    pub fn togglePause(self: *State) void {
        self.paused = !self.paused;
    }

    // direction

    pub fn goLeft(self: *State) !void {
        if (self.direction == Direction.Right) {
            return;
        }
        self.direction = Direction.Left;
        return self.move();
    }

    pub fn goRight(self: *State) !void {
        if (self.direction == Direction.Left) {
            return;
        }
        self.direction = Direction.Right;
        return self.move();
    }

    pub fn goUp(self: *State) !void {
        if (self.direction == Direction.Down) {
            return;
        }
        self.direction = Direction.Up;
        return self.move();
    }

    pub fn goDown(self: *State) !void {
        if (self.direction == Direction.Up) {
            return;
        }
        self.direction = Direction.Down;
        return self.move();
    }

    // movement

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

    pub fn move(self: *State) !void {
        if (self.paused) {
            return;
        }
        switch (self.direction) {
            Direction.Left => try self.moveLeft(),
            Direction.Right => try self.moveRight(),
            Direction.Up => try self.moveUp(),
            Direction.Down => try self.moveDown(),
        }
    }
};
