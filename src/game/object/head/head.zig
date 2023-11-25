const std = @import("std");
const gl = @import("zopengl");
const zstbi = @import("zstbi");
const matrix = @import("../../math/matrix.zig");
const glutils = @import("../../gl/gl.zig");
const grid = @import("../../grid.zig");
const state = @import("../../state.zig");

pub const HeadErr = error{Error};
const objectName = "head";

// zig fmt: off
const upVertices: [16]gl.Float = [_]gl.Float{
                // positions   // texture coords
                1,  1,          0.5, 0,
                1,  -1,         0.5, 1,
                -1, -1,         1, 1,
                -1, 1,          1, 0,
};

const downVertices: [16]gl.Float = [_]gl.Float{
                // positions   // texture coords
                1,  1,          0.5, 1,
                1,  -1,         0.5, 0,
                -1, -1,         1, 0,
                -1, 1,          1, 1,
};

const leftVertices: [16]gl.Float = [_]gl.Float{
                // positions   // texture coords
                1,  1,          0, 1,
                1,  -1,         0, 0,
                -1, -1,         0.5, 0,
                -1, 1,          0.5, 1,
};

const rightVertices: [16]gl.Float = [_]gl.Float{
                // positions   // texture coords
                1,  1,          0.5, 1,
                1,  -1,         0.5, 0,
                -1, -1,         0, 0,
                -1, 1,          0, 1,
};
// zig fmt: on

pub const Head = struct {
    state: *state.State,
    indices: [6]gl.Uint,
    VAOs: [4]gl.Uint,
    texture: gl.Uint,
    shaderProgram: gl.Uint,

    pub fn init(gameState: *state.State) !Head {
        var rv = Head{
            .state = gameState,
            .indices = [_]gl.Uint{
                0, 1, 3,
                1, 2, 3,
            },
            .VAOs = [_]gl.Uint{
                undefined,
                undefined,
                undefined,
                undefined,
            },
            .texture = undefined,
            .shaderProgram = undefined,
        };

        const combinedVertices = [4][16]gl.Float{ leftVertices, rightVertices, upVertices, downVertices };
        for (combinedVertices, 0..) |vertices, i| {
            const VAO = try glutils.initVAO(objectName);
            _ = try glutils.initVBO(objectName);
            _ = try rv.initEBO();
            try initData(vertices);
            rv.VAOs[i] = VAO;
        }

        rv.texture = try rv.initTexture();
        const vertexShader = try glutils.initVertexShader(@embedFile("shaders/head.vs"), objectName);
        const fragmentShader = try glutils.initFragmentShader(@embedFile("shaders/head.fs"), objectName);
        rv.shaderProgram = try glutils.initProgram("BACKGROUND", &[_]gl.Uint{ vertexShader, fragmentShader });
        return rv;
    }

    fn initEBO(self: Head) !gl.Uint {
        const EBO = glutils.initEBO(objectName);
        gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, self.indices.len * @sizeOf(gl.Int), &self.indices, gl.STATIC_DRAW);
        const e = gl.getError();
        if (e != gl.NO_ERROR) {
            std.debug.print("{s} buffer data error: {d}\n", .{ objectName, e });
            return HeadErr.Error;
        }
        return EBO;
    }

    fn initTexture(self: Head) !gl.Uint {
        _ = self;
        var texture: gl.Uint = undefined;
        var e: gl.Uint = 0;
        gl.genTextures(1, &texture);
        gl.bindTexture(gl.TEXTURE_2D, texture);

        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);

        const grassBytes: [:0]const u8 = @embedFile("../../assets/textures/snake_head.png");
        var image = try zstbi.Image.loadFromMemory(grassBytes, 4);
        defer image.deinit();
        std.debug.print("loaded image {d}x{d}\n", .{ image.width, image.height });

        const width: gl.Int = @as(gl.Int, @intCast(image.width));
        const height: gl.Int = @as(gl.Int, @intCast(image.height));
        const imageData: *const anyopaque = image.data.ptr;
        gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, width, height, 0, gl.RGBA, gl.UNSIGNED_BYTE, imageData);
        e = gl.getError();
        if (e != gl.NO_ERROR) {
            std.debug.print("error: {d}\n", .{e});
            return HeadErr.Error;
        }
        gl.generateMipmap(gl.TEXTURE_2D);
        e = gl.getError();
        if (e != gl.NO_ERROR) {
            std.debug.print("error: {d}\n", .{e});
            return HeadErr.Error;
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
            return HeadErr.Error;
        }
        gl.vertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, 4 * @sizeOf(gl.Float), @as(*anyopaque, @ptrFromInt(2 * @sizeOf(gl.Float))));
        gl.enableVertexAttribArray(1);
        e = gl.getError();
        if (e != gl.NO_ERROR) {
            std.debug.print("error: {d}\n", .{e});
            return HeadErr.Error;
        }
    }

    fn initShaderProgram(self: Head) !gl.Uint {
        return glutils.initProgram("HEAD", &[_]gl.Uint{ self.vertexShader, self.fragmentShader });
    }

    pub fn draw(self: Head) !void {
        const headCoords = self.state.segments.items[0];
        const posX: gl.Float = try self.state.grid.indexToGridPosition(headCoords.x);
        const posY: gl.Float = try self.state.grid.indexToGridPosition(headCoords.y);
        if (self.state.direction == .Left) {
            try self.drawHead(self.VAOs[0], posX, posY);
        } else if (self.state.direction == .Right) {
            try self.drawHead(self.VAOs[1], posX, posY);
        } else if (self.state.direction == .Up) {
            try self.drawHead(self.VAOs[2], posX, posY);
        } else {
            try self.drawHead(self.VAOs[3], posX, posY);
        }
    }

    fn drawHead(self: Head, VAO: gl.Uint, posX: gl.Float, posY: gl.Float) !void {
        const transV = self.state.grid.objectTransform(posX, posY);
        try glutils.draw(self.shaderProgram, VAO, self.texture, &self.indices, transV);
    }
};
