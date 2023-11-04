const std = @import("std");
const gl = @import("zopengl");

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
        std.debug.print("vertexShaderSource: {s}\n", .{vertexShaderSource.ptr});
        var vertexShader: gl.Uint = gl.createShader(gl.VERTEX_SHADER);
        gl.shaderSource(vertexShader, 1, &[_][*c]const u8{vertexShaderSource.ptr}, null);
        gl.compileShader(vertexShader);
        var success: gl.Int = 0;
        gl.getShaderiv(vertexShader, gl.COMPILE_STATUS, &success);
        if (success == 0) {
            var infoLog: [512]u8 = undefined;
            var logSize: gl.Int = 0;
            gl.getShaderInfoLog(vertexShader, 512, &logSize, &infoLog);
            var i: usize = @intCast(logSize);
            std.debug.print("ERROR::SHADER::VERTEX::COMPILATION_FAILED\n{s}\n", .{infoLog[0..i]});
            return SegmentErr.Error;
        }
        var infoLog: [512]u8 = undefined;
        var logSize: gl.Int = 0;
        gl.getShaderInfoLog(vertexShader, 512, &logSize, &infoLog);
        var i: usize = @intCast(logSize);
        std.debug.print("INFO::SHADER::VERTEX::LINKING_SUCCESS\n{s}\n", .{infoLog[0..i]});

        return vertexShader;
    }

    fn initFragmentShader(_: Segment) !gl.Uint {
        var fragmentShaderSource: [:0]const u8 = @embedFile("shaders/segment.fs");
        std.debug.print("fragmentShaderSource: {s}\n", .{fragmentShaderSource.ptr});
        var fragmentShader: gl.Uint = gl.createShader(gl.FRAGMENT_SHADER);
        gl.shaderSource(fragmentShader, 1, &[_][*c]const u8{fragmentShaderSource.ptr}, null);
        gl.compileShader(fragmentShader);
        var success: gl.Int = 0;
        gl.getShaderiv(fragmentShader, gl.COMPILE_STATUS, &success);
        if (success == 0) {
            var infoLog: [512]u8 = undefined;
            var logSize: gl.Int = 0;
            gl.getShaderInfoLog(fragmentShader, 512, &logSize, &infoLog);
            var i: usize = @intCast(logSize);
            std.debug.print("ERROR::SHADER::FRAGMENT::COMPILATION_FAILED\n{s}\n", .{infoLog[0..i]});
            return SegmentErr.Error;
        }
        var infoLog: [512]u8 = undefined;
        var logSize: gl.Int = 0;
        gl.getShaderInfoLog(fragmentShader, 512, logSize, &infoLog);
        var i: usize = @intCast(logSize);
        std.debug.print("INFO::SHADER::FRAGMENT::LINKING_SUCCESS\n{s}\n", .{infoLog[0..i]});

        return fragmentShader;
    }

    fn initShaderProgram(self: Segment) !gl.Uint {
        var shaderProgram: gl.Uint = gl.createProgram();
        gl.attachShader(shaderProgram, self.vertexShader);
        gl.attachShader(shaderProgram, self.fragmentShader);
        var e = gl.getError();
        if (e != gl.NO_ERROR) {
            std.debug.print("error: {d}\n", .{e});
            return SegmentErr.Error;
        }

        gl.linkProgram(shaderProgram);
        var success: gl.Int = 0;
        gl.getProgramiv(shaderProgram, gl.LINK_STATUS, &success);
        if (success == 0) {
            var infoLog: [512]u8 = undefined;
            var logSize: gl.Int = 0;
            gl.getProgramInfoLog(shaderProgram, 512, &logSize, &infoLog);
            var i: usize = @intCast(logSize);
            std.debug.print("ERROR::SHADER::PROGRAM::LINKING_FAILED\n{s}\n", .{infoLog[0..i]});
            return SegmentErr.Error;
        }
        var infoLog: [512]u8 = undefined;
        var logSize: gl.Int = 0;
        gl.getProgramInfoLog(shaderProgram, 512, &logSize, &infoLog);
        var i: usize = @intCast(logSize);
        std.debug.print("INFO::SHADER::PROGRAM::LINKING_SUCCESS {d}\n{s}\n", .{ i, infoLog[0..i] });

        gl.deleteShader(self.vertexShader);
        gl.deleteShader(self.fragmentShader);
        e = gl.getError();
        if (e != gl.NO_ERROR) {
            std.debug.print("error: {d}\n", .{e});
            return SegmentErr.Error;
        }
        std.debug.print("program set up \n", .{});
        return shaderProgram;
    }
};
