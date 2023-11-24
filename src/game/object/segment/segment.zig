const std = @import("std");
const gl = @import("zopengl");
const zstbi = @import("zstbi");
const matrix = @import("../../math/matrix.zig");
const glutils = @import("../../gl/gl.zig");
const grid = @import("../../grid.zig");
const state = @import("../../state.zig");

pub const SegmentErr = error{Error};
const objectName = "segment";

const SegmentType = enum(u2) {
    Sideways = 0,
    Left = 1,
    Right = 2,
};

// zig fmt: off
const sideWaysVertices: [16]gl.Float = [_]gl.Float{
                // positions   // texture coords
                1,  1,          0.5, 1,
                1,  -1,         0.5, 0,
                -1, -1,         1, 0,
                -1, 1,          1, 1,
};

const leftVertices: [16]gl.Float = [_]gl.Float{
                // positions   // texture coords
                1,  1,          1, 1,
                1,  -1,         1, 0,
                -1, -1,         0.5, 0,
                -1, 1,          0.5, 1,
};

const rightVertices: [16]gl.Float = [_]gl.Float{
                // positions   // texture coords
                1,  1,          0, 1,
                1,  -1,         0, 0,
                -1, -1,         0.5, 0,
                -1, 1,          0.5, 1,
};
// zig fmt: on

pub const Segment = struct {
    indices: [6]gl.Uint,
    VAOs: [3]gl.Uint,
    texture: gl.Uint,
    shaderProgram: gl.Uint,

    pub fn init() !Segment {
        var rv = Segment{
            .indices = [_]gl.Uint{
                0, 1, 3,
                1, 2, 3,
            },
            .VAOs = [_]gl.Uint{
                undefined,
                undefined,
                undefined,
            },
            .texture = undefined,
            .shaderProgram = undefined,
        };
        const combinedVertices = [3][16]gl.Float{ sideWaysVertices, leftVertices, rightVertices };
        for (combinedVertices, 0..) |vertices, i| {
            const VAO = try glutils.initVAO(objectName);
            _ = try glutils.initVBO(objectName);
            _ = try rv.initEBO();
            try initData(vertices);
            rv.VAOs[i] = VAO;
        }
        rv.texture = try rv.initTexture();
        const vertexShader = try glutils.initVertexShader(@embedFile("shaders/segment.vs"), objectName);
        const fragmentShader = try glutils.initFragmentShader(@embedFile("shaders/segment.fs"), objectName);
        rv.shaderProgram = try glutils.initProgram("BACKGROUND", &[_]gl.Uint{ vertexShader, fragmentShader });
        return rv;
    }

    fn initEBO(self: Segment) !gl.Uint {
        const EBO = glutils.initEBO(objectName);
        gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, self.indices.len * @sizeOf(gl.Int), &self.indices, gl.STATIC_DRAW);
        const e = gl.getError();
        if (e != gl.NO_ERROR) {
            std.debug.print("{s} buffer data error: {d}\n", .{ objectName, e });
            return SegmentErr.Error;
        }
        return EBO;
    }

    fn initTexture(self: Segment) !gl.Uint {
        _ = self;
        var texture: gl.Uint = undefined;
        var e: gl.Uint = 0;
        gl.genTextures(1, &texture);
        gl.bindTexture(gl.TEXTURE_2D, texture);

        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);

        const snake_ext: [:0]const u8 = @embedFile("../../assets/textures/snake_extended.png");
        var image = try zstbi.Image.loadFromMemory(snake_ext, 4);
        defer image.deinit();
        std.debug.print("loaded image {d}x{d}\n", .{ image.width, image.height });

        const width: gl.Int = @as(gl.Int, @intCast(image.width));
        const height: gl.Int = @as(gl.Int, @intCast(image.height));
        const imageData: *const anyopaque = image.data.ptr;
        gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, width, height, 0, gl.RGBA, gl.UNSIGNED_BYTE, imageData);
        e = gl.getError();
        if (e != gl.NO_ERROR) {
            std.debug.print("error: {d}\n", .{e});
            return SegmentErr.Error;
        }
        gl.generateMipmap(gl.TEXTURE_2D);
        e = gl.getError();
        if (e != gl.NO_ERROR) {
            std.debug.print("error: {d}\n", .{e});
            return SegmentErr.Error;
        }
        return texture;
    }

    fn initData(vertices: [16]gl.Float) !void {
        gl.bufferData(gl.ARRAY_BUFFER, vertices.len * @sizeOf(gl.Float), &vertices, gl.STATIC_DRAW);
        gl.vertexAttribPointer(0, 2, gl.FLOAT, gl.FALSE, 4 * @sizeOf(gl.Float), null);
        gl.enableVertexAttribArray(0);
        var e = gl.getError();
        if (e != gl.NO_ERROR) {
            std.debug.print("error: {d}\n", .{e});
            return SegmentErr.Error;
        }
        gl.vertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, 4 * @sizeOf(gl.Float), @as(*anyopaque, @ptrFromInt(2 * @sizeOf(gl.Float))));
        gl.enableVertexAttribArray(1);
        e = gl.getError();
        if (e != gl.NO_ERROR) {
            std.debug.print("error: {d}\n", .{e});
            return SegmentErr.Error;
        }
    }

    fn initShaderProgram(self: Segment) !gl.Uint {
        return glutils.initProgram("SEGMENT", &[_]gl.Uint{ self.vertexShader, self.fragmentShader });
    }

    pub fn draw(self: Segment, gameGrid: grid.Grid, gameState: *state.State) !void {
        for (gameState.segments.items[1..], 0..) |coords, i| {
            const posX: gl.Float = try gameGrid.indexToGridPosition(coords.x);
            const posY: gl.Float = try gameGrid.indexToGridPosition(coords.y);
            try drawSegment(self.shaderProgram, self.VAOs[i % 2], self.texture, self.indices, posX, posY, gameGrid);
        }
    }

    fn drawSegment(
        shaderProgram: gl.Uint,
        VAO: gl.Uint,
        texture: gl.Uint,
        indices: [6]gl.Uint,
        posX: gl.Float,
        posY: gl.Float,
        gameGrid: grid.Grid,
    ) !void {
        gl.useProgram(shaderProgram);
        var e = gl.getError();
        if (e != gl.NO_ERROR) {
            std.debug.print("error: {d}\n", .{e});
            return SegmentErr.Error;
        }
        gl.activeTexture(gl.TEXTURE0);
        gl.bindTexture(gl.TEXTURE_2D, texture);
        e = gl.getError();
        if (e != gl.NO_ERROR) {
            std.debug.print("bind texture error: {d}\n", .{e});
            return SegmentErr.Error;
        }
        gl.bindVertexArray(VAO);
        e = gl.getError();
        if (e != gl.NO_ERROR) {
            std.debug.print("error: {d}\n", .{e});
            return SegmentErr.Error;
        }

        const transV = gameGrid.objectTransform(posX, posY);

        var transform = matrix.scaleTranslateMat3(transV);
        const location = gl.getUniformLocation(shaderProgram, "transform");
        gl.uniformMatrix3fv(location, 1, gl.FALSE, &transform);
        e = gl.getError();
        if (e != gl.NO_ERROR) {
            std.debug.print("error: {d}\n", .{e});
            return SegmentErr.Error;
        }

        const textureLoc = gl.getUniformLocation(shaderProgram, "texture1");
        gl.uniform1i(textureLoc, 0);
        e = gl.getError();
        if (e != gl.NO_ERROR) {
            std.debug.print("error: {d}\n", .{e});
            return SegmentErr.Error;
        }

        gl.drawElements(gl.TRIANGLES, @as(c_int, @intCast((indices.len))), gl.UNSIGNED_INT, null);
        if (e != gl.NO_ERROR) {
            std.debug.print("error: {d}\n", .{e});
            return SegmentErr.Error;
        }
    }
};
