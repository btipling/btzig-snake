const std = @import("std");
const matrix = @import("../../math/matrix.zig");
const gl = @import("zopengl");
const glutils = @import("../../gl/gl.zig");
const grid = @import("../../grid.zig");

pub const FoodErr = error{Error};
const objectName = "food";

pub const Food = struct {
    num_vertices: gl.Uint,
    vertices: [202]gl.Float, // 2 * (num_vertices + 1) because we need to add the center point
    indices: [299]gl.Uint, // 3 * (num_vertices - 1) because we need to add the center point
    VAO: gl.Uint,
    shaderProgram: gl.Uint,

    pub fn init() !Food {
        var rv = Food{
            .num_vertices = 100,
            .vertices = undefined,
            .indices = undefined,
            .VAO = undefined,
            .shaderProgram = undefined,
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

    pub fn draw(self: Food, posX: gl.Float, posY: gl.Float, gameGrid: grid.Grid) !void {
        gl.useProgram(self.shaderProgram);
        var e = gl.getError();
        if (e != gl.NO_ERROR) {
            std.debug.print("error: {d}\n", .{e});
            return FoodErr.Error;
        }
        gl.bindVertexArray(self.VAO);
        e = gl.getError();
        if (e != gl.NO_ERROR) {
            std.debug.print("error: {d}\n", .{e});
            return FoodErr.Error;
        }

        const transV = gameGrid.objectTransform(posX, posY);

        var transform = matrix.scaleTranslateMat3(transV);
        const location = gl.getUniformLocation(self.shaderProgram, "transform");
        gl.uniformMatrix3fv(location, 1, gl.FALSE, &transform);
        e = gl.getError();
        if (e != gl.NO_ERROR) {
            std.debug.print("error: {d}\n", .{e});
            return FoodErr.Error;
        }

        gl.drawElements(gl.TRIANGLES, @as(c_int, @intCast((self.indices.len))), gl.UNSIGNED_INT, null);
        if (e != gl.NO_ERROR) {
            std.debug.print("error: {d}\n", .{e});
            return FoodErr.Error;
        }
    }
};
