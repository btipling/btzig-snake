const std = @import("std");
const zstbi = @import("zstbi");
const gl = @import("zopengl");
const matrix = @import("../math/matrix.zig");

pub const GLErr = error{Error};

pub fn initVAO(msg: []const u8) !gl.Uint {
    var VAO: gl.Uint = undefined;
    gl.genVertexArrays(1, &VAO);
    gl.bindVertexArray(VAO);
    const e = gl.getError();
    if (e != gl.NO_ERROR) {
        std.debug.print("init vao error: {s} {d}\n", .{ msg, e });
        return GLErr.Error;
    }
    return VAO;
}

pub fn initVBO(msg: []const u8) !gl.Uint {
    var VBO: gl.Uint = undefined;
    gl.genBuffers(1, &VBO);
    gl.bindBuffer(gl.ARRAY_BUFFER, VBO);
    const e = gl.getError();
    if (e != gl.NO_ERROR) {
        std.debug.print("init vbo error: {s} {d}\n", .{ msg, e });
        return GLErr.Error;
    }
    return VBO;
}

pub fn initTexture(img: [:0]const u8, msg: []const u8) !gl.Uint {
    var texture: gl.Uint = undefined;
    var e: gl.Uint = 0;
    gl.genTextures(1, &texture);
    gl.bindTexture(gl.TEXTURE_2D, texture);
    if (e != gl.NO_ERROR) {
        std.debug.print("{s} gen or bind texture error: {d}\n", .{ msg, e });
        return GLErr.Error;
    }

    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
    e = gl.getError();
    if (e != gl.NO_ERROR) {
        std.debug.print("{s} text parameter i error: {d}\n", .{ msg, e });
        return GLErr.Error;
    }

    var image = try zstbi.Image.loadFromMemory(img, 4);
    defer image.deinit();
    std.debug.print("loaded image {s} {d}x{d}\n", .{ msg, image.width, image.height });

    const width: gl.Int = @as(gl.Int, @intCast(image.width));
    const height: gl.Int = @as(gl.Int, @intCast(image.height));
    const imageData: *const anyopaque = image.data.ptr;
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, width, height, 0, gl.RGBA, gl.UNSIGNED_BYTE, imageData);
    e = gl.getError();
    if (e != gl.NO_ERROR) {
        std.debug.print("{s} gext image 2d error: {d}\n", .{ msg, e });
        return GLErr.Error;
    }
    gl.generateMipmap(gl.TEXTURE_2D);
    e = gl.getError();
    if (e != gl.NO_ERROR) {
        std.debug.print("{s} generate mimap error: {d}\n", .{ msg, e });
        return GLErr.Error;
    }
    return texture;
}

pub fn initVertexShader(vertexShaderSource: [:0]const u8, msg: []const u8) !gl.Uint {
    var buffer: [20]u8 = undefined;
    const shaderMsg = try std.fmt.bufPrint(&buffer, "{s}: VERTEX", .{msg});
    return initShader(shaderMsg, vertexShaderSource, gl.VERTEX_SHADER);
}

pub fn initFragmentShader(fragmentShaderSource: [:0]const u8, msg: []const u8) !gl.Uint {
    var buffer: [20]u8 = undefined;
    const shaderMsg = try std.fmt.bufPrint(&buffer, "{s}: FRAGMENT", .{msg});
    return initShader(shaderMsg, fragmentShaderSource, gl.FRAGMENT_SHADER);
}

pub fn initEBO(msg: []const u8) !gl.Uint {
    var EBO: gl.Uint = undefined;
    gl.genBuffers(1, &EBO);
    var e = gl.getError();
    if (e != gl.NO_ERROR) {
        std.debug.print("init ebo error: {s} {d}\n", .{ msg, e });
        return GLErr.Error;
    }
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, EBO);
    e = gl.getError();
    if (e != gl.NO_ERROR) {
        std.debug.print("bind ebo buff error: {s} {d}\n", .{ msg, e });
        return GLErr.Error;
    }
    return EBO;
}

pub fn initProgram(name: []const u8, shaders: []const gl.Uint) !gl.Uint {
    const shaderProgram: gl.Uint = gl.createProgram();
    for (shaders) |shader| {
        gl.attachShader(shaderProgram, shader);
    }
    var e = gl.getError();
    if (e != gl.NO_ERROR) {
        std.debug.print("{s} error: {d}\n", .{ name, e });
        return GLErr.Error;
    }

    gl.linkProgram(shaderProgram);
    var success: gl.Int = 0;
    gl.getProgramiv(shaderProgram, gl.LINK_STATUS, &success);
    if (success == 0) {
        var infoLog: [512]u8 = undefined;
        var logSize: gl.Int = 0;
        gl.getProgramInfoLog(shaderProgram, 512, &logSize, &infoLog);
        const i: usize = @intCast(logSize);
        std.debug.print("ERROR::SHADER::{s}::PROGRAM::LINKING_FAILED\n{s}\n", .{ name, infoLog[0..i] });
        return GLErr.Error;
    }
    var infoLog: [512]u8 = undefined;
    var logSize: gl.Int = 0;
    gl.getProgramInfoLog(shaderProgram, 512, &logSize, &infoLog);
    const i: usize = @intCast(logSize);
    std.debug.print("INFO::SHADER::{s}::PROGRAM::LINKING_SUCCESS {d}\n{s}\n", .{ name, i, infoLog[0..i] });

    for (shaders) |shader| {
        gl.deleteShader(shader);
    }

    e = gl.getError();
    if (e != gl.NO_ERROR) {
        std.debug.print("{s} error: {d}\n", .{ name, e });
        return GLErr.Error;
    }
    std.debug.print("{s} program set up \n", .{name});
    return shaderProgram;
}

pub fn initShader(name: []const u8, source: [:0]const u8, shaderType: c_uint) !gl.Uint {
    std.debug.print("{s} source: {s}\n", .{ name, source.ptr });

    const shader: gl.Uint = gl.createShader(shaderType);
    gl.shaderSource(shader, 1, &[_][*c]const u8{source.ptr}, null);
    gl.compileShader(shader);

    var success: gl.Int = 0;
    gl.getShaderiv(shader, gl.COMPILE_STATUS, &success);
    if (success == 0) {
        var infoLog: [512]u8 = undefined;
        var logSize: gl.Int = 0;
        gl.getShaderInfoLog(shader, 512, &logSize, &infoLog);
        const i: usize = @intCast(logSize);
        std.debug.print("ERROR::SHADER::{s}::COMPILATION_FAILED\n{s}\n", .{ name, infoLog[0..i] });
        return GLErr.Error;
    }

    var infoLog: [512]u8 = undefined;
    var logSize: gl.Int = 0;
    gl.getShaderInfoLog(shader, 512, &logSize, &infoLog);
    const i: usize = @intCast(logSize);
    std.debug.print("INFO::SHADER::{s}::LINKING_SUCCESS\n{s}\n", .{ name, infoLog[0..i] });

    return shader;
}

pub fn draw(shaderProgram: gl.Uint, VAO: gl.Uint, texture: ?gl.Uint, indices: []const gl.Uint, transV: [4]gl.Float) !void {
    gl.useProgram(shaderProgram);
    var e = gl.getError();
    if (e != gl.NO_ERROR) {
        std.debug.print("error: {d}\n", .{e});
        return GLErr.Error;
    }
    if (texture) |t| {
        gl.activeTexture(gl.TEXTURE0);
        gl.bindTexture(gl.TEXTURE_2D, t);
        e = gl.getError();
        if (e != gl.NO_ERROR) {
            std.debug.print("bind texture error: {d}\n", .{e});
            return GLErr.Error;
        }
    }
    gl.bindVertexArray(VAO);
    e = gl.getError();
    if (e != gl.NO_ERROR) {
        std.debug.print("error: {d}\n", .{e});
        return GLErr.Error;
    }

    var transform = matrix.scaleTranslateMat3(transV);
    const location = gl.getUniformLocation(shaderProgram, "transform");
    gl.uniformMatrix3fv(location, 1, gl.FALSE, &transform);
    e = gl.getError();
    if (e != gl.NO_ERROR) {
        std.debug.print("error: {d}\n", .{e});
        return GLErr.Error;
    }

    if (texture) |_| {
        const textureLoc = gl.getUniformLocation(shaderProgram, "texture1");
        gl.uniform1i(textureLoc, 0);
        e = gl.getError();
        if (e != gl.NO_ERROR) {
            std.debug.print("error: {d}\n", .{e});
            return GLErr.Error;
        }
    }

    gl.drawElements(gl.TRIANGLES, @as(c_int, @intCast((indices.len))), gl.UNSIGNED_INT, null);
    if (e != gl.NO_ERROR) {
        std.debug.print("error: {d}\n", .{e});
        return GLErr.Error;
    }
}
