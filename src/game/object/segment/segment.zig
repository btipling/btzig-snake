const std = @import("std");
const matrix = @import("../../math/matrix.zig");
const gl = @import("zopengl");
const glutils = @import("../../gl/gl.zig");

pub const SegmentErr = error{Error};

pub const Segment = struct {
    vertices: [8]gl.Float,
    indices: [6]gl.Uint,
    VAO: gl.Uint,
    VBO: gl.Uint,
    EBO: gl.Uint,
    vertexShader: gl.Uint,
    fragmentShader: gl.Uint,
    shaderProgram: gl.Uint,

    pub fn init() !Segment {
        var rv = Segment{
            .vertices = [_]gl.Float{
                0.5,  0.5,
                0.5,  -0.5,
                -0.5, -0.5,
                -0.5, 0.5,
            },
            .indices = [_]gl.Uint{
                0, 1, 3,
                1, 2, 3,
            },
            .VAO = undefined,
            .VBO = undefined,
            .EBO = undefined,
            .vertexShader = undefined,
            .fragmentShader = undefined,
            .shaderProgram = undefined,
        };
        rv.VAO = try rv.initVAO();
        rv.VBO = try rv.initVBO();
        rv.EBO = try rv.initEBO();
        rv.vertexShader = try rv.initVertexShader();
        rv.fragmentShader = try rv.initFragmentShader();
        rv.shaderProgram = try rv.initShaderProgram();
        try rv.initData();
        return rv;
    }

    fn initVAO(_: Segment) !gl.Uint {
        var VAO: gl.Uint = undefined;
        gl.genVertexArrays(1, &VAO);
        gl.bindVertexArray(VAO);
        var e = gl.getError();
        if (e != gl.NO_ERROR) {
            std.debug.print("error: {d}\n", .{e});
            return SegmentErr.Error;
        }
        return VAO;
    }

    fn initVBO(_: Segment) !gl.Uint {
        var VBO: gl.Uint = undefined;
        gl.genBuffers(1, &VBO);
        gl.bindBuffer(gl.ARRAY_BUFFER, VBO);
        var e = gl.getError();
        if (e != gl.NO_ERROR) {
            std.debug.print("error: {d}\n", .{e});
            return SegmentErr.Error;
        }
        return VBO;
    }

    fn initEBO(self: Segment) !gl.Uint {
        var EBO: gl.Uint = undefined;
        gl.genBuffers(1, &EBO);
        gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, EBO);
        gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, self.indices.len * @sizeOf(gl.Int), &self.indices, gl.STATIC_DRAW);
        var e = gl.getError();
        if (e != gl.NO_ERROR) {
            std.debug.print("error: {d}\n", .{e});
            return SegmentErr.Error;
        }
        return EBO;
    }

    fn initData(self: Segment) !void {
        gl.bufferData(gl.ARRAY_BUFFER, self.vertices.len * @sizeOf(gl.Float), &self.vertices, gl.STATIC_DRAW);
        gl.vertexAttribPointer(0, 2, gl.FLOAT, gl.FALSE, 2 * @sizeOf(gl.Float), null);
        gl.enableVertexAttribArray(0);
        var e = gl.getError();
        if (e != gl.NO_ERROR) {
            std.debug.print("error: {d}\n", .{e});
            return SegmentErr.Error;
        }
    }

    fn initVertexShader(_: Segment) !gl.Uint {
        var vertexShaderSource: [:0]const u8 = @embedFile("shaders/segment.vs");
        return glutils.initShader("VERTEX", vertexShaderSource, gl.VERTEX_SHADER);
    }

    fn initFragmentShader(_: Segment) !gl.Uint {
        var fragmentShaderSource: [:0]const u8 = @embedFile("shaders/segment.fs");
        return glutils.initShader("VERTEX", fragmentShaderSource, gl.FRAGMENT_SHADER);
    }

    fn initShaderProgram(self: Segment) !gl.Uint {
        return glutils.initProgram("SEGMENT", &[_]gl.Uint{ self.vertexShader, self.fragmentShader });
    }

    pub fn draw(self: Segment, posX: gl.Float, posY: gl.Float) !void {
        gl.useProgram(self.shaderProgram);
        var e = gl.getError();
        if (e != gl.NO_ERROR) {
            std.debug.print("error: {d}\n", .{e});
            return SegmentErr.Error;
        }
        gl.bindVertexArray(self.VAO);
        e = gl.getError();
        if (e != gl.NO_ERROR) {
            std.debug.print("error: {d}\n", .{e});
            return SegmentErr.Error;
        }

        var scaleX: gl.Float = 0.05;
        var scaleY: gl.Float = 0.05;
        var transX: gl.Float = -1.0 + (posX * scaleX) + (scaleX / 2);
        var transY: gl.Float = 1.0 - (posY * scaleY) - (scaleY / 2);
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
            return SegmentErr.Error;
        }

        gl.drawElements(gl.TRIANGLES, @as(c_int, @intCast((self.indices.len))), gl.UNSIGNED_INT, null);
        if (e != gl.NO_ERROR) {
            std.debug.print("error: {d}\n", .{e});
            return SegmentErr.Error;
        }
    }
};
