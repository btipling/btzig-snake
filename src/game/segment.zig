const std = @import("std");
const gl = @import("zopengl");

pub const SegmentErr = error{Error};

pub const Segment = struct {
    vertices: [8]gl.Float,
    indices: [6]gl.Uint,
    VAO: gl.Uint,
    VBO: gl.Uint,
    EBO: gl.Uint,

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
        };
        rv.VAO = try rv.initVAO();
        rv.VBO = try rv.initVBO();
        rv.EBO = try rv.initEBO();
        try rv.initData();
        return rv;
    }

    fn initVAO(_: Segment) !gl.Uint {
        var i: gl.Uint = undefined;
        gl.genVertexArrays(1, &i);
        gl.bindVertexArray(i);
        var e = gl.getError();
        if (e != gl.NO_ERROR) {
            std.debug.print("error: {d}\n", .{e});
            return SegmentErr.Error;
        }
        return i;
    }

    fn initVBO(_: Segment) !gl.Uint {
        var i: gl.Uint = undefined;
        gl.genBuffers(1, &i);
        gl.bindBuffer(gl.ARRAY_BUFFER, i);
        var e = gl.getError();
        if (e != gl.NO_ERROR) {
            std.debug.print("error: {d}\n", .{e});
            return SegmentErr.Error;
        }
        return i;
    }

    fn initEBO(self: Segment) !gl.Uint {
        var i: gl.Uint = undefined;
        gl.genBuffers(1, &i);
        gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, i);
        gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, self.indices.len * @sizeOf(gl.Int), &self.indices, gl.STATIC_DRAW);
        var e = gl.getError();
        if (e != gl.NO_ERROR) {
            std.debug.print("error: {d}\n", .{e});
            return SegmentErr.Error;
        }
        return i;
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
};
