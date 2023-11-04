const std = @import("std");
const sdl = @import("zsdl");
const gl = @import("zopengl");
const matrix = @import("math/matrix.zig");
const cfg = @import("config.zig");
const segment = @import("segment.zig");

pub fn start() !void {
    _ = sdl.setHint(sdl.hint_windows_dpi_awareness, "system");

    try sdl.init(.{ .audio = true, .video = true });
    defer sdl.quit();

    const gl_major = 4;
    const gl_minor = 6;
    try sdl.gl.setAttribute(.context_profile_mask, @intFromEnum(sdl.gl.Profile.core));
    try sdl.gl.setAttribute(.context_major_version, gl_major);
    try sdl.gl.setAttribute(.context_minor_version, gl_minor);
    try sdl.gl.setAttribute(.context_flags, @as(i32, @bitCast(sdl.gl.ContextFlags{ .forward_compatible = true })));

    const window = try sdl.Window.create(
        cfg.game_name,
        sdl.Window.pos_undefined,
        sdl.Window.pos_undefined,
        cfg.windows_width,
        cfg.windows_height,
        .{ .opengl = true, .allow_highdpi = true },
    );
    defer window.destroy();

    const gl_context = try sdl.gl.createContext(window);
    defer sdl.gl.deleteContext(gl_context);

    try sdl.gl.makeCurrent(window, gl_context);
    try sdl.gl.setSwapInterval(0);

    try gl.loadCoreProfile(sdl.gl.getProcAddress, gl_major, gl_minor);

    {
        var w: i32 = undefined;
        var h: i32 = undefined;

        try window.getSize(&w, &h);
        std.debug.print("Window size is {d}x{d}\n", .{ w, h });

        sdl.gl.getDrawableSize(window, &w, &h);
        std.debug.print("Drawable size is {d}x{d}\n", .{ w, h });
    }

    var seg = try segment.Segment.init();

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
        return;
    } else {
        var infoLog: [512]u8 = undefined;
        var logSize: gl.Int = 0;
        gl.getShaderInfoLog(vertexShader, 512, &logSize, &infoLog);
        var i: usize = @intCast(logSize);
        std.debug.print("INFO::SHADER::VERTEX::LINKING_SUCCESS\n{s}\n", .{infoLog[0..i]});
    }

    var fragmentShaderSource: [:0]const u8 = @embedFile("shaders/segment.fs");
    std.debug.print("fragmentShaderSource: {s}\n", .{fragmentShaderSource.ptr});
    var fragmentShader: gl.Uint = gl.createShader(gl.FRAGMENT_SHADER);
    gl.shaderSource(fragmentShader, 1, &[_][*c]const u8{fragmentShaderSource.ptr}, null);
    gl.compileShader(fragmentShader);
    gl.getShaderiv(fragmentShader, gl.COMPILE_STATUS, &success);
    if (success == 0) {
        var infoLog: [512]u8 = undefined;
        var logSize: gl.Int = 0;
        gl.getShaderInfoLog(fragmentShader, 512, &logSize, &infoLog);
        var i: usize = @intCast(logSize);
        std.debug.print("ERROR::SHADER::FRAGMENT::COMPILATION_FAILED\n{s}\n", .{infoLog[0..i]});
        return;
    } else {
        var infoLog: [512]u8 = undefined;
        var logSize: gl.Int = 0;
        gl.getShaderInfoLog(vertexShader, 512, logSize, &infoLog);
        var i: usize = @intCast(logSize);
        std.debug.print("INFO::SHADER::FRAGMENT::LINKING_SUCCESS\n{s}\n", .{infoLog[0..i]});
    }

    var shaderProgram: gl.Uint = gl.createProgram();
    gl.attachShader(shaderProgram, vertexShader);
    gl.attachShader(shaderProgram, fragmentShader);
    var e = gl.getError();
    if (e != gl.NO_ERROR) {
        std.debug.print("error: {d}\n", .{e});
        return;
    }

    gl.linkProgram(shaderProgram);
    gl.getProgramiv(shaderProgram, gl.LINK_STATUS, &success);
    if (success == 0) {
        var infoLog: [512]u8 = undefined;
        var logSize: gl.Int = 0;
        gl.getProgramInfoLog(shaderProgram, 512, &logSize, &infoLog);
        var i: usize = @intCast(logSize);
        std.debug.print("ERROR::SHADER::PROGRAM::LINKING_FAILED\n{s}\n", .{infoLog[0..i]});
        return;
    } else {
        var infoLog: [512]u8 = undefined;
        var logSize: gl.Int = 0;
        gl.getProgramInfoLog(shaderProgram, 512, &logSize, &infoLog);
        var i: usize = @intCast(logSize);
        std.debug.print("INFO::SHADER::PROGRAM::LINKING_SUCCESS {d}\n{s}\n", .{ i, infoLog[0..i] });
    }
    gl.deleteShader(vertexShader);
    gl.deleteShader(fragmentShader);
    e = gl.getError();
    if (e != gl.NO_ERROR) {
        std.debug.print("error: {d}\n", .{e});
        return;
    }
    std.debug.print("program set up \n", .{});

    var speed = cfg.initial_speed;
    var boxX = cfg.initial_start_x;
    var boxY = cfg.initial_start_y;
    main_loop: while (true) {
        var event: sdl.Event = undefined;
        while (sdl.pollEvent(&event)) {
            if (event.type == .quit) {
                break :main_loop;
            } else if (event.type == .keydown) {
                switch (event.key.keysym.sym) {
                    .q => break :main_loop,
                    .escape => break :main_loop,
                    .left => boxX -= speed,
                    .a => boxX -= speed,
                    .right => boxX += speed,
                    .d => boxX += speed,
                    .up => boxY -= speed,
                    .w => boxY -= speed,
                    .down => boxY += speed,
                    .s => boxY += speed,
                    else => {},
                }
                if (boxX < 0) {
                    boxX = 0.0;
                }
                if (boxY < 0) {
                    boxY = 0.0;
                }
                if (boxX >= cfg.grid_size) {
                    boxX = cfg.grid_size;
                }
                if (boxY >= cfg.grid_size) {
                    boxY = cfg.grid_size;
                }
            }
        }
        gl.clearBufferfv(gl.COLOR, 0, &[_]f32{ 0.2, 0.4, 0.8, 1.0 });

        gl.useProgram(shaderProgram);
        e = gl.getError();
        if (e != gl.NO_ERROR) {
            std.debug.print("error: {d}\n", .{e});
            return;
        }
        gl.bindVertexArray(seg.VAO);
        e = gl.getError();
        if (e != gl.NO_ERROR) {
            std.debug.print("error: {d}\n", .{e});
            return;
        }

        var scaleX: gl.Float = 0.05;
        var scaleY: gl.Float = 0.05;
        var posX: gl.Float = -1.0 + (boxX * scaleX) + (scaleX / 2);
        var posY: gl.Float = 1.0 - (boxY * scaleY) - (scaleY / 2);
        var transV = [_]gl.Float{
            scaleX, scaleY,
            posX,   posY,
        };

        var transform = matrix.scaleTranslateMat3(transV);
        const location = gl.getUniformLocation(shaderProgram, "transform");
        gl.uniformMatrix3fv(location, 1, gl.FALSE, &transform);
        e = gl.getError();
        if (e != gl.NO_ERROR) {
            std.debug.print("error: {d}\n", .{e});
            return;
        }

        gl.drawElements(gl.TRIANGLES, @as(c_int, @intCast((seg.indices.len))), gl.UNSIGNED_INT, null);
        if (e != gl.NO_ERROR) {
            std.debug.print("error: {d}\n", .{e});
            return;
        }

        sdl.gl.swapWindow(window);
    }
}
