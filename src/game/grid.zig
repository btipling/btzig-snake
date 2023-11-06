const gl = @import("zopengl");
const std = @import("std");

pub const GridErr = error{Error};

pub const Grid = struct {
    size: gl.Float,

    pub fn init(size: gl.Float) Grid {
        return Grid{
            .size = size,
        };
    }

    pub fn constrainGridPosition(self: Grid, gridIndex: gl.Float) gl.Float {
        var rv = gridIndex;
        if (rv < 1.0) {
            return 1.0;
        } else if (rv > self.size - 1.0) {
            return self.size - 1.0;
        } else {
            return rv;
        }
    }

    pub fn indexToGridPosition(self: Grid, gridIndex: gl.Float) !gl.Float {
        var rv = gridIndex - 1.0;
        if (rv < 0.0) {
            return GridErr.Error;
        } else if (rv > self.size - 1.0) {
            return GridErr.Error;
        } else {
            return rv;
        }
    }

    pub fn randomGridPosition(self: Grid, seed: u32) [2]gl.Float {
        var prng = std.rand.DefaultPrng.init(seed);
        const random = prng.random();
        const max = @as(u32, @intFromFloat(self.size));
        const x = @as(gl.Float, @floatFromInt(random.uintAtMost(u32, max)));
        const y = @as(gl.Float, @floatFromInt(random.uintAtMost(u32, max)));
        std.debug.print("x: {d}, y: {d}\n", .{ x, y });
        return [_]gl.Float{ self.constrainGridPosition(x), self.constrainGridPosition(y) };
    }
};
