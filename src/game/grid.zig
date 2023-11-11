const gl = @import("zopengl");
const std = @import("std");

pub const GridErr = error{Error};

pub const Grid = struct {
    size: gl.Float,
    scaleFactor: gl.Float,

    pub fn init(size: gl.Float) Grid {
        return Grid{
            .size = size,
            .scaleFactor = 1.0 / size,
        };
    }

    pub fn constrainGridPosition(self: Grid, gridIndex: gl.Float) gl.Float {
        var rv = gridIndex;
        if (rv < 1.0) {
            return 0.0;
        } else if (rv >= self.size) {
            return self.size - 1.0;
        } else {
            return rv;
        }
    }

    pub fn indexToGridPosition(self: Grid, gridIndex: gl.Float) !gl.Float {
        var rv = gridIndex;
        if (rv < 0.0) {
            return GridErr.Error;
        } else if (rv > self.size) {
            return GridErr.Error;
        } else {
            return rv;
        }
    }

    pub fn randomGridPosition(self: Grid, i: u32) [2]gl.Float {
        var prng = std.rand.DefaultPrng.init(@as(u64, @intCast(i)) + @as(u64, @intCast(std.time.milliTimestamp())));
        const random = prng.random();
        const max = @as(u32, @intFromFloat(self.size));
        const x = @as(gl.Float, @floatFromInt(random.uintAtMost(u32, max)));
        const y = @as(gl.Float, @floatFromInt(random.uintAtMost(u32, max)));
        std.debug.print("Food moved to x: {d}, y: {d}\n", .{ x, y });
        return [_]gl.Float{ self.constrainGridPosition(x), self.constrainGridPosition(y) };
    }
};
