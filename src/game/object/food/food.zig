const std = @import("std");
const gl = @import("zopengl");
const glutils = @import("../../gl/gl.zig");
const state = @import("../../state.zig");
const bug = @import("bug.zig");

pub const FoodErr = error{Error};
const objectName = "food";

pub const Food = struct {
    state: *state.State,
    num_vertices: gl.Uint,
    vertices: [202]gl.Float, // 2 * (num_vertices + 1) because we need to add the center point
    indices: [299]gl.Uint, // 3 * (num_vertices - 1) because we need to add the center point
    VAO: gl.Uint,
    shaderProgram: gl.Uint,
    bug: bug.Bug,

    pub fn init(gameState: *state.State) !Food {
        const bugObj = try bug.Bug.init(gameState);
        var rv = Food{
            .state = gameState,
            .num_vertices = 100,
            .vertices = undefined,
            .indices = undefined,
            .VAO = undefined,
            .shaderProgram = undefined,
            .bug = bugObj,
        };

        rv.vertices[0] = 0.0;
        rv.vertices[1] = 0.0;
        for (0..rv.num_vertices + 1) |i| {
            const angle = @as(gl.Float, @floatFromInt(i)) / @as(gl.Float, @floatFromInt(rv.num_vertices)) * 2 * 3.14159;
            rv.vertices[i * 2] = @floatCast(@sin(angle));
            rv.vertices[i * 2 + 1] = @floatCast(@cos(angle));
        }
        for (0..99) |i| {
            rv.indices[i * 3] = 0;
            rv.indices[i * 3 + 1] = @as(gl.Uint, @intCast(i + 1));
            rv.indices[i * 3 + 2] = @as(gl.Uint, @intCast(i + 2));
        }
        rv.VAO = try glutils.initVAO(objectName);
        _ = try glutils.initVBO(objectName);
        _ = try rv.initEBO();
        const vertexShader = try glutils.initVertexShader(@embedFile("shaders/food.vs"), objectName);
        const fragmentShader = try glutils.initFragmentShader(@embedFile("shaders/food.fs"), objectName);
        rv.shaderProgram = try glutils.initProgram("BACKGROUND", &[_]gl.Uint{ vertexShader, fragmentShader });
        try rv.initData();
        return rv;
    }

    fn initEBO(self: Food) !gl.Uint {
        const EBO = glutils.initEBO(objectName);
        gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, self.indices.len * @sizeOf(gl.Int), &self.indices, gl.STATIC_DRAW);
        const e = gl.getError();
        if (e != gl.NO_ERROR) {
            std.debug.print("{s} buffer data error: {d}\n", .{ objectName, e });
            return FoodErr.Error;
        }
        return EBO;
    }

    fn initData(self: Food) !void {
        gl.bufferData(gl.ARRAY_BUFFER, self.vertices.len * @sizeOf(gl.Float), &self.vertices, gl.STATIC_DRAW);
        gl.vertexAttribPointer(0, 2, gl.FLOAT, gl.FALSE, 2 * @sizeOf(gl.Float), null);
        gl.enableVertexAttribArray(0);
        const e = gl.getError();
        if (e != gl.NO_ERROR) {
            std.debug.print("error: {d}\n", .{e});
            return FoodErr.Error;
        }
    }

    pub fn draw(self: Food) !void {
        var transV = self.state.grid.objectTransform(self.state.foodX, self.state.foodY);
        transV[0] = transV[0] * 1.5;
        transV[1] = transV[1] * 1.5;
        try glutils.draw(self.shaderProgram, self.VAO, null, &self.indices, transV);
        try self.bug.draw();
    }
};
