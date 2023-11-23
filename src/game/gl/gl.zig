const std = @import("std");
const gl = @import("zopengl");

pub const GLErr = error{Error};

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
