const std = @import("std");
const gl = @import("zopengl");
const zstbi = @import("zstbi");
const matrix = @import("../../math/matrix.zig");
const glutils = @import("../../gl/gl.zig");
const grid = @import("../../grid.zig");

pub const BackgroundErr = error{Error};

pub const Background = struct {
    vertices: [16]gl.Float,
    indices: [6]gl.Uint,
    VAO: gl.Uint,
    VBO: gl.Uint,
    EBO: gl.Uint,
    texture: gl.Uint,
    vertexShader: gl.Uint,
    fragmentShader: gl.Uint,
    shaderProgram: gl.Uint,
    gridSize: gl.Float,

    pub fn init(gridSize: gl.Float) !Background {
        std.debug.print("init background\n", .{});
        var rv = Background{
            .vertices = [_]gl.Float{
                // zig fmt: off
                // positions   // texture coords
                1,  1,          1, 1,
                1,  -1,         1, 0,
                -1, -1,         0, 0,
                -1, 1,          0, 1,
                // zig fmt: on
            },
            .indices = [_]gl.Uint{
                0, 1, 3,
                1, 2, 3,
            },
            .VAO = undefined,
            .VBO = undefined,
            .EBO = undefined,
            .texture = undefined,
            .vertexShader = undefined,
            .fragmentShader = undefined,
            .shaderProgram = undefined,
            .gridSize = gridSize,
        };
        rv.VAO = try rv.initVAO();
        rv.VBO = try rv.initVBO();
        rv.EBO = try rv.initEBO();
        rv.texture = try rv.initTexture();
        rv.vertexShader = try rv.initVertexShader();
        rv.fragmentShader = try rv.initFragmentShader();
        rv.shaderProgram = try rv.initShaderProgram();
        try rv.initData();
        return rv;
    }

    fn initVAO(_: Background) !gl.Uint {
        var VAO: gl.Uint = undefined;
        gl.genVertexArrays(1, &VAO);
        gl.bindVertexArray(VAO);
        var e = gl.getError();
        if (e != gl.NO_ERROR) {
            std.debug.print("error: {d}\n", .{e});
            return BackgroundErr.Error;
        }
        return VAO;
    }

    fn initVBO(_: Background) !gl.Uint {
        var VBO: gl.Uint = undefined;
        gl.genBuffers(1, &VBO);
        gl.bindBuffer(gl.ARRAY_BUFFER, VBO);
        var e = gl.getError();
        if (e != gl.NO_ERROR) {
            std.debug.print("error: {d}\n", .{e});
            return BackgroundErr.Error;
        }
        return VBO;
    }

    fn initEBO(self: Background) !gl.Uint {
        var EBO: gl.Uint = undefined;
        gl.genBuffers(1, &EBO);
        gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, EBO);
        gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, self.indices.len * @sizeOf(gl.Int), &self.indices, gl.STATIC_DRAW);
        var e = gl.getError();
        if (e != gl.NO_ERROR) {
            std.debug.print("error: {d}\n", .{e});
            return BackgroundErr.Error;
        }
        return EBO;
    }

    fn initTexture(self: Background) !gl.Uint {
        _ = self;
        var texture: gl.Uint = undefined;
        var e: gl.Uint = 0;
        gl.genTextures(1, &texture);
        gl.bindTexture(gl.TEXTURE_2D, texture);

        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);

        var grassBytes: [:0]const u8 = @embedFile("../../assets/textures/grass.png");
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
            return BackgroundErr.Error;
        }
        gl.generateMipmap(gl.TEXTURE_2D);
        e = gl.getError();
        if (e != gl.NO_ERROR) {
            std.debug.print("error: {d}\n", .{e});
            return BackgroundErr.Error;
        }
        return texture;
    }

    fn initData(self: Background) !void {
        gl.bufferData(gl.ARRAY_BUFFER, self.vertices.len * @sizeOf(gl.Float), &self.vertices, gl.STATIC_DRAW);
        gl.vertexAttribPointer(0, 2, gl.FLOAT, gl.FALSE, 4 * @sizeOf(gl.Float), null);
        gl.enableVertexAttribArray(0);
        gl.vertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, 4 * @sizeOf(gl.Float), @as(*anyopaque, @ptrFromInt(2 * @sizeOf(gl.Float))));
        gl.enableVertexAttribArray(1);
        var e = gl.getError();
        if (e != gl.NO_ERROR) {
            std.debug.print("error: {d}\n", .{e});
            return BackgroundErr.Error;
        }
    }

    fn initVertexShader(_: Background) !gl.Uint {
        var vertexShaderSource: [:0]const u8 = @embedFile("shaders/background.vs");
        return glutils.initShader("VERTEX", vertexShaderSource, gl.VERTEX_SHADER);
    }

    fn initFragmentShader(_: Background) !gl.Uint {
        var fragmentShaderSource: [:0]const u8 = @embedFile("shaders/background.fs");
        return glutils.initShader("FRAGMENT", fragmentShaderSource, gl.FRAGMENT_SHADER);
    }

    fn initShaderProgram(self: Background) !gl.Uint {
        return glutils.initProgram("BACKGROUND", &[_]gl.Uint{ self.vertexShader, self.fragmentShader });
    }

    pub fn draw(self: Background, gameGrid: grid.Grid) !void {
        gl.useProgram(self.shaderProgram);
        var e = gl.getError();
        if (e != gl.NO_ERROR) {
            std.debug.print("use program error: {d}\n", .{e});
            return BackgroundErr.Error;
        }
        gl.activeTexture(gl.TEXTURE0);
        gl.bindTexture(gl.TEXTURE_2D, self.texture);
        e = gl.getError();
        if (e != gl.NO_ERROR) {
            std.debug.print("bind texture error: {d}\n", .{e});
            return BackgroundErr.Error;
        }
        gl.bindVertexArray(self.VAO);
        e = gl.getError();
        if (e != gl.NO_ERROR) {
            std.debug.print("bind vertex error: {d}\n", .{e});
            return BackgroundErr.Error;
        }

        var transV = gameGrid.gridTransform();

        var transform = matrix.scaleTranslateMat3(transV);
        const location = gl.getUniformLocation(self.shaderProgram, "transform");
        gl.uniformMatrix3fv(location, 1, gl.FALSE, &transform);
        e = gl.getError();
        if (e != gl.NO_ERROR) {
            std.debug.print("error: {d}\n", .{e});
            return BackgroundErr.Error;
        }

        const textureLoc = gl.getUniformLocation(self.shaderProgram, "texture1");
        gl.uniform1i(textureLoc, 0);
        e = gl.getError();
        if (e != gl.NO_ERROR) {
            std.debug.print("error: {d}\n", .{e});
            return BackgroundErr.Error;
        }

        gl.drawElements(gl.TRIANGLES, @as(c_int, @intCast((self.indices.len))), gl.UNSIGNED_INT, null);
        if (e != gl.NO_ERROR) {
            std.debug.print("error: {d}\n", .{e});
            return BackgroundErr.Error;
        }
    }
};
