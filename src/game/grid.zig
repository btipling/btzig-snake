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

    pub fn bgScale(_: Grid) [2]gl.Float {
        // Assume a square grid in a 16:9 screen with grid on the left and the right a score panel
        return [_]gl.Float{ 1.0, 1.0 };
    }

    pub fn bgTranslate(self: Grid) [2]gl.Float {
        const scaleX: gl.Float = self.bgScale()[0];
        const scaleY: gl.Float = self.bgScale()[1];
        const transX: gl.Float = -1.0 + scaleX;
        const transY: gl.Float = 1.0 - scaleY;
        return [_]gl.Float{ transX, transY };
    }

    pub fn bgTransform(self: Grid) [4]gl.Float {
        const scale = self.bgScale();
        const trans = self.bgTranslate();
        return [_]gl.Float{
            scale[0], scale[1],
            trans[0], trans[1],
        };
    }

    pub fn gridScale(_: Grid) [2]gl.Float {
        // Assume a square grid in a 16:9 screen with grid on the left and the right a score panel
        return [_]gl.Float{ 0.5625, 1.0 };
    }

    pub fn objectScale(self: Grid) [2]gl.Float {
        return [_]gl.Float{ (1 / self.size) * self.gridScale()[0], 1 / self.size };
    }

    pub fn gridTranslate(self: Grid) [2]gl.Float {
        // grid should translate to left of window
        const scaleX: gl.Float = self.gridScale()[0];
        const scaleY: gl.Float = self.gridScale()[1];
        const transX: gl.Float = -1.0 + scaleX;
        const transY: gl.Float = 1.0 - scaleY;
        return [_]gl.Float{ transX, transY };
    }

    pub fn gridTranslateCenter(self: Grid) [2]gl.Float {
        // grid should translate to center of window
        const scaleX: gl.Float = self.gridScale()[0];
        const scaleY: gl.Float = self.gridScale()[1];
        const transX: gl.Float = -0.5 + scaleX;
        const transY: gl.Float = 1.0 - scaleY;
        return [_]gl.Float{ transX, transY };
    }

    pub fn gridTransform(self: Grid) [4]gl.Float {
        const scale = self.gridScale();
        const trans = self.gridTranslate();
        return [_]gl.Float{
            scale[0], scale[1],
            trans[0], trans[1],
        };
    }

    pub fn gridTransformCenter(self: Grid) [4]gl.Float {
        const scale = self.gridScale();
        const trans = self.gridTranslateCenter();
        return [_]gl.Float{
            scale[0], scale[1],
            trans[0], trans[1],
        };
    }

    pub fn objectTransform(self: Grid, posX: gl.Float, posY: gl.Float) [4]gl.Float {
        const scale = self.objectScale();
        const trans = self.objectTranslate(posX, posY);
        return [_]gl.Float{
            scale[0], scale[1],
            trans[0], trans[1],
        };
    }

    pub fn objectTranslate(self: Grid, posX: gl.Float, posY: gl.Float) [2]gl.Float {
        const scaleX: gl.Float = self.objectScale()[0];
        const scaleY: gl.Float = self.objectScale()[1];
        const transX: gl.Float = -1.0 + (posX * scaleX * 2) + scaleX;
        const transY: gl.Float = 1.0 - (posY * scaleY * 2) - scaleY;
        return [_]gl.Float{ transX, transY };
    }

    pub fn constrainGridPosition(self: Grid, gridIndex: gl.Float) gl.Float {
        if (gridIndex < 1.0) {
            return 0.0;
        } else if (gridIndex >= self.size) {
            return self.size - 1.0;
        } else {
            return gridIndex;
        }
    }

    pub fn indexToGridPosition(self: Grid, gridIndex: gl.Float) !gl.Float {
        if (gridIndex < 0.0) {
            return GridErr.Error;
        } else if (gridIndex > self.size) {
            return GridErr.Error;
        } else {
            return gridIndex;
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
