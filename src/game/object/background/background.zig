const std = @import("std");
const gl = @import("zopengl");
const glutils = @import("../../gl/gl.zig");
const state = @import("../../state.zig");

pub const BackgroundErr = error{Error};
const objectName = "background";

pub const Background = struct {
    state: *state.State,
    vertices: [16]gl.Float,
    indices: [6]gl.Uint,
    VAO: gl.Uint,
    texture: gl.Uint,
    shaderProgram: gl.Uint,

    pub fn init(gameState: *state.State) !Background {
        std.debug.print("init background\n", .{});
        var rv = Background{
            .state = gameState,
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
            .texture = undefined,
            .shaderProgram = undefined,
        };
        rv.VAO = try glutils.initVAO(objectName);
        _ = try glutils.initVBO(objectName);
        _ = try rv.initEBO();
        rv.texture = try glutils.initTexture( @embedFile("../../assets/textures/snake_bg.png"), objectName);
        const vertexShader = try glutils.initVertexShader(@embedFile("shaders/background.vs"), objectName);
        const fragmentShader = try glutils.initFragmentShader(@embedFile("shaders/background.fs"), objectName);
        rv.shaderProgram = try glutils.initProgram("BACKGROUND", &[_]gl.Uint{ vertexShader, fragmentShader });
        try rv.initData();
        return rv;
    }

    fn initEBO(self: Background) !gl.Uint {
        const EBO = glutils.initEBO(objectName);
        gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, self.indices.len * @sizeOf(gl.Int), &self.indices, gl.STATIC_DRAW);
        const e = gl.getError();
        if (e != gl.NO_ERROR) {
            std.debug.print("{s} buffer data error: {d}\n", .{objectName, e});
            return BackgroundErr.Error;
        }
        return EBO;
    }

    fn initData(self: Background) !void {
        gl.bufferData(gl.ARRAY_BUFFER, self.vertices.len * @sizeOf(gl.Float), &self.vertices, gl.STATIC_DRAW);
        gl.vertexAttribPointer(0, 2, gl.FLOAT, gl.FALSE, 4 * @sizeOf(gl.Float), null);
        gl.enableVertexAttribArray(0);
        gl.vertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, 4 * @sizeOf(gl.Float), @as(*anyopaque, @ptrFromInt(2 * @sizeOf(gl.Float))));
        gl.enableVertexAttribArray(1);
        const e = gl.getError();
        if (e != gl.NO_ERROR) {
            std.debug.print("error: {d}\n", .{e});
            return BackgroundErr.Error;
        }
    }

    pub fn draw(self: Background) !void {
        const transV = self.state.grid.bgTransform();
        try glutils.draw(self.shaderProgram, self.VAO, self.texture, &self.indices, transV);
    }
};
