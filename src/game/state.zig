const std = @import("std");
const gl = @import("zopengl");
const grid = @import("grid.zig");

pub const State = struct {
    score: u32,
    headX: gl.Float,
    headY: gl.Float,
    foodX: gl.Float,
    foodY: gl.Float,
    grid: grid.Grid,
    pub fn init(gameGrid: grid.Grid, startX: gl.Float, startY: gl.Float) State {
        return State{
            .score = 0,
            .headX = startX,
            .headY = startY,
            .foodX = 0.0,
            .foodY = 0.0,
            .grid = gameGrid,
        };
    }
    pub fn generateFoodPosition(self: *State) void {
        var foodPos = self.grid.randomGridPosition(self.score);
        self.foodX = foodPos[0];
        self.foodY = foodPos[1];
    }
    pub fn updateHeadPosition(self: *State, x: gl.Float, y: gl.Float) void {
        self.headX = self.grid.constrainGridPosition(x);
        self.headY = self.grid.constrainGridPosition(y);
        if (self.headX == self.foodX and self.headY == self.foodY) {
            const newScore = self.score + 1;
            self.score = newScore;
            State.generateFoodPosition(self);
            std.debug.print("Score: {d}\n", .{newScore});
        }
    }
};
