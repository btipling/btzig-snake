const std = @import("std");
const matrix = @import("../../math/matrix.zig");
const gl = @import("zopengl");
const glutils = @import("../../gl/gl.zig");

pub const FoodErr = error{Error};

pub const Food = struct {
    num_vertices: gl.Uint,
    vertices: [202]gl.Float, // 2 * (num_vertices + 1) because we need to add the center point
    indices: [299]gl.Uint, // 3 * (num_vertices - 1) because we need to add the center point
    VAO: gl.Uint,
    VBO: gl.Uint,
    EBO: gl.Uint,
    vertexShader: gl.Uint,
    fragmentShader: gl.Uint,
    shaderProgram: gl.Uint,

    pub fn init() !Food {
        var rv = Food{
            .num_vertices = 100,
            .vertices = undefined,
            .indices = undefined,
            .VAO = undefined,
            .VBO = undefined,
            .EBO = undefined,
            .vertexShader = undefined,
            .fragmentShader = undefined,
            .shaderProgram = undefined,
        };

        rv.vertices[0] = 0.0;
        rv.vertices[1] = 0.0;
        for (0..rv.num_vertices + 1) |i| {
            var angle = @as(gl.Float, @floatFromInt(i)) / @as(gl.Float, @floatFromInt(rv.num_vertices)) * 2 * 3.14159;
            rv.vertices[i * 2] = @floatCast(@sin(angle));
            rv.vertices[i * 2 + 1] = @floatCast(@cos(angle));
        }
        for (0..99) |i| {
            rv.indices[i * 3] = 0;
            rv.indices[i * 3 + 1] = @as(gl.Uint, @intCast(i + 1));
            rv.indices[i * 3 + 2] = @as(gl.Uint, @intCast(i + 2));
        }

        rv.VAO = try rv.initVAO();
        rv.VBO = try rv.initVBO();
        rv.EBO = try rv.initEBO();
        rv.vertexShader = try rv.initVertexShader();
        rv.fragmentShader = try rv.initFragmentShader();
        rv.shaderProgram = try rv.initShaderProgram();
        try rv.initData();
        return rv;
    }

    fn initVAO(_: Food) !gl.Uint {
        var VAO: gl.Uint = undefined;
        gl.genVertexArrays(1, &VAO);
        gl.bindVertexArray(VAO);
        var e = gl.getError();
        if (e != gl.NO_ERROR) {
            std.debug.print("error: {d}\n", .{e});
            return FoodErr.Error;
        }
        return VAO;
    }

    fn initVBO(_: Food) !gl.Uint {
        var VBO: gl.Uint = undefined;
        gl.genBuffers(1, &VBO);
        gl.bindBuffer(gl.ARRAY_BUFFER, VBO);
        var e = gl.getError();
        if (e != gl.NO_ERROR) {
            std.debug.print("error: {d}\n", .{e});
            return FoodErr.Error;
        }
        return VBO;
    }

    fn initEBO(self: Food) !gl.Uint {
        var EBO: gl.Uint = undefined;
        gl.genBuffers(1, &EBO);
        gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, EBO);
        gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, self.indices.len * @sizeOf(gl.Int), &self.indices, gl.STATIC_DRAW);
        var e = gl.getError();
        if (e != gl.NO_ERROR) {
            std.debug.print("error: {d}\n", .{e});
            return FoodErr.Error;
        }
        return EBO;
    }

    fn initData(self: Food) !void {
        gl.bufferData(gl.ARRAY_BUFFER, self.vertices.len * @sizeOf(gl.Float), &self.vertices, gl.STATIC_DRAW);
        gl.vertexAttribPointer(0, 2, gl.FLOAT, gl.FALSE, 2 * @sizeOf(gl.Float), null);
        gl.enableVertexAttribArray(0);
        var e = gl.getError();
        if (e != gl.NO_ERROR) {
            std.debug.print("error: {d}\n", .{e});
            return FoodErr.Error;
        }
    }

    fn initVertexShader(_: Food) !gl.Uint {
        var vertexShaderSource: [:0]const u8 = @embedFile("shaders/food.vs");
        return glutils.initShader("VERTEX", vertexShaderSource, gl.VERTEX_SHADER);
    }

    fn initFragmentShader(_: Food) !gl.Uint {
        var fragmentShaderSource: [:0]const u8 = @embedFile("shaders/food.fs");
        return glutils.initShader("VERTEX", fragmentShaderSource, gl.FRAGMENT_SHADER);
    }

    fn initShaderProgram(self: Food) !gl.Uint {
        return glutils.initProgram("FOOD", &[_]gl.Uint{ self.vertexShader, self.fragmentShader });
    }

    pub fn draw(self: Food, posX: gl.Float, posY: gl.Float) !void {
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

        // var scaleX: gl.Float = 1;
        // var scaleY: gl.Float = 1;
        // let's make the food for the snake tiny
        var scaleX: gl.Float = 0.02;
        var scaleY: gl.Float = 0.02;
        var transX: gl.Float = -1.0 + (posX * 0.025) + 0.025;
        var transY: gl.Float = 1.0 - (posY * 0.025) - 0.025;
        var transV = [_]gl.Float{
            scaleX, scaleY,
            transX, transY,
        };

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
