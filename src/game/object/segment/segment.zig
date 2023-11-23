const std = @import("std");
const gl = @import("zopengl");
const zstbi = @import("zstbi");
const matrix = @import("../../math/matrix.zig");
const glutils = @import("../../gl/gl.zig");
const grid = @import("../../grid.zig");

pub const SegmentErr = error{Error};
const objectName = "segment";

pub const Segment = struct {
    vertices: [16]gl.Float,
    indices: [6]gl.Uint,
    VAO: gl.Uint,
    texture: gl.Uint,
    shaderProgram: gl.Uint,

    pub fn initSideways() !Segment {
        return Segment.init([_]gl.Float{
            // zig fmt: off
                // positions   // texture coords
                1,  1,          0.5, 1,
                1,  -1,         0.5, 0,
                -1, -1,         1, 0,
                -1, 1,          1, 1,
                // zig fmt: on
            });
    }

    pub fn initLeft() !Segment {
        return Segment.init([_]gl.Float{
            // zig fmt: off
                // positions   // texture coords
                1,  1,          1, 1,
                1,  -1,         1, 0,
                -1, -1,         0.5, 0,
                -1, 1,          0.5, 1,
                // zig fmt: on
            });
    }

    pub fn initRight() !Segment {
        return Segment.init([_]gl.Float{
            // zig fmt: off
                // positions   // texture coords
                1,  1,          0, 1,
                1,  -1,         0, 0,
                -1, -1,         0.5, 0,
                -1, 1,          0.5, 1,
                // zig fmt: on
            });
    }

    pub fn init(vertices: [16]gl.Float) !Segment {
        var rv = Segment{
            .vertices = vertices,
            .indices = [_]gl.Uint{
                0, 1, 3,
                1, 2, 3,
            },
            .VAO = undefined,
            .texture = undefined,
            .shaderProgram = undefined,
        };
        rv.VAO = try glutils.initVAO(objectName);
        _ = try glutils.initVBO(objectName);
        _ = try rv.initEBO();
        rv.texture = try rv.initTexture();
        const vertexShader = try glutils.initVertexShader(@embedFile("shaders/segment.vs"), objectName);
        const fragmentShader = try glutils.initFragmentShader(@embedFile("shaders/segment.fs"), objectName);
        rv.shaderProgram = try glutils.initProgram("BACKGROUND", &[_]gl.Uint{ vertexShader, fragmentShader });
        try rv.initData();
        return rv;
    }

    fn initEBO(self: Segment) !gl.Uint {
        const EBO = glutils.initEBO(objectName);
        gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, self.indices.len * @sizeOf(gl.Int), &self.indices, gl.STATIC_DRAW);
        const e = gl.getError();
        if (e != gl.NO_ERROR) {
            std.debug.print("{s} buffer data error: {d}\n", .{objectName, e});
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

    fn initData(self: Segment) !void {
        gl.bufferData(gl.ARRAY_BUFFER, self.vertices.len * @sizeOf(gl.Float), &self.vertices, gl.STATIC_DRAW);
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

    fn initVertexShader(_: Segment) !gl.Uint {
        const vertexShaderSource: [:0]const u8 = @embedFile("shaders/segment.vs");
        return glutils.initShader("VERTEX", vertexShaderSource, gl.VERTEX_SHADER);
    }

    fn initFragmentShader(_: Segment) !gl.Uint {
        const fragmentShaderSource: [:0]const u8 = @embedFile("shaders/segment.fs");
        return glutils.initShader("FRAGMENT", fragmentShaderSource, gl.FRAGMENT_SHADER);
    }

    fn initShaderProgram(self: Segment) !gl.Uint {
        return glutils.initProgram("SEGMENT", &[_]gl.Uint{ self.vertexShader, self.fragmentShader });
    }

    pub fn draw(self: Segment, posX: gl.Float, posY: gl.Float, gameGrid: grid.Grid) !void {
        gl.useProgram(self.shaderProgram);
        var e = gl.getError();
        if (e != gl.NO_ERROR) {
            std.debug.print("error: {d}\n", .{e});
            return SegmentErr.Error;
        }
        gl.activeTexture(gl.TEXTURE0);
        gl.bindTexture(gl.TEXTURE_2D, self.texture);
        e = gl.getError();
        if (e != gl.NO_ERROR) {
            std.debug.print("bind texture error: {d}\n", .{e});
            return SegmentErr.Error;
        }
        gl.bindVertexArray(self.VAO);
        e = gl.getError();
        if (e != gl.NO_ERROR) {
            std.debug.print("error: {d}\n", .{e});
            return SegmentErr.Error;
        }
        
        const transV = gameGrid.objectTransform(posX,posY);

        var transform = matrix.scaleTranslateMat3(transV);
        const location = gl.getUniformLocation(self.shaderProgram, "transform");
        gl.uniformMatrix3fv(location, 1, gl.FALSE, &transform);
        e = gl.getError();
        if (e != gl.NO_ERROR) {
            std.debug.print("error: {d}\n", .{e});
            return SegmentErr.Error;
        }

        const textureLoc = gl.getUniformLocation(self.shaderProgram, "texture1");
        gl.uniform1i(textureLoc, 0);
        e = gl.getError();
        if (e != gl.NO_ERROR) {
            std.debug.print("error: {d}\n", .{e});
            return SegmentErr.Error;
        }

        gl.drawElements(gl.TRIANGLES, @as(c_int, @intCast((self.indices.len))), gl.UNSIGNED_INT, null);
        if (e != gl.NO_ERROR) {
            std.debug.print("error: {d}\n", .{e});
            return SegmentErr.Error;
        }
    }
};
