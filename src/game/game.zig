const std = @import("std");
const glfw = @import("zglfw");
const zaudio = @import("zaudio");
const zgui = @import("zgui");
const gl = @import("zopengl");
const zstbi = @import("zstbi");
const math = std.math;
const cfg = @import("config.zig");
const segment = @import("object/segment/segment.zig");
const food = @import("object/food/food.zig");
const background = @import("object/background/background.zig");
const splash = @import("object/splash/splash.zig");
const ui = @import("ui/ui.zig");
const grid = @import("grid.zig");
const state = @import("state.zig");
const controls = @import("controls.zig");
const sound = @import("sound.zig");

const embedded_font_data = @embedFile("assets/fonts/PressStart2P-Regular.ttf");

pub fn run() !void {
    glfw.init() catch {
        std.log.err("Failed to initialize GLFW library.", .{});
        return;
    };
    defer glfw.terminate();

    const gl_major = 4;
    const gl_minor = 6;
    glfw.windowHintTyped(.context_version_major, gl_major);
    glfw.windowHintTyped(.context_version_minor, gl_minor);
    glfw.windowHintTyped(.opengl_profile, .opengl_core_profile);
    glfw.windowHintTyped(.opengl_forward_compat, true);
    glfw.windowHintTyped(.client_api, .opengl_api);
    glfw.windowHintTyped(.doublebuffer, true);
    glfw.windowHintTyped(.resizable, false);
    const window = glfw.Window.create(cfg.windows_width, cfg.windows_height, cfg.game_name, null) catch {
        std.log.err("Failed to create game window.", .{});
        return;
    };
    defer window.destroy();
    window.setSizeLimits(800, 800, -1, -1);
    window.setInputMode(glfw.InputMode.cursor, glfw.Cursor.Mode.disabled);

    glfw.makeContextCurrent(window);
    glfw.swapInterval(1);

    try gl.loadCoreProfile(glfw.getProcAddress, gl_major, gl_minor);

    {
        const dimensions: [2]i32 = window.getSize();
        const w = dimensions[0];
        const h = dimensions[1];
        std.debug.print("Window size is {d}x{d}\n", .{ w, h });
    }

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    zgui.init(allocator);
    defer zgui.deinit();

    zgui.backend.init(window);
    defer zgui.backend.deinit();

    zstbi.init(allocator);
    defer zstbi.deinit();
    zstbi.setFlipVerticallyOnLoad(true);

    const font_size = 24.0;
    const font_large = zgui.io.addFontFromMemory(embedded_font_data, math.floor(font_size * 1.1));
    zgui.io.setDefaultFont(font_large);

    zaudio.init(allocator);
    defer zaudio.deinit();
    const engine = try zaudio.Engine.create(null);
    defer engine.destroy();

    var gameSound = sound.Sound.init(engine);
    defer gameSound.destroy();

    try gameSound.playStartSound();

    const gameGrid = grid.Grid.init(cfg.grid_size);
    var gameState = try state.State.init(
        gameGrid,
        cfg.initial_speed,
        cfg.initial_delay,
        cfg.initial_start_x,
        cfg.initial_start_y,
        allocator,
        &gameSound,
    );

    var stateInst = &gameState;
    stateInst.generateFoodPosition();

    var snake = try segment.Segment.init(stateInst);
    var foodItem = try food.Food.init(stateInst);
    var bg = try background.Background.init(stateInst);
    var gameSplash = try splash.Splash.init(stateInst);
    var gameUI = try ui.UI.init(stateInst, window, snake, foodItem.bug);

    var lastTick = std.time.milliTimestamp();
    main_loop: while (!window.shouldClose()) {
        glfw.pollEvents();
        const quit = try controls.handleKey(stateInst, window);
        if (quit) {
            break :main_loop;
        }
        if (std.time.milliTimestamp() - lastTick > gameState.delay) {
            try stateInst.move();
            lastTick = std.time.milliTimestamp();
        }
        gl.clearBufferfv(gl.COLOR, 0, &[_]f32{ 0.2, 0.4, 0.8, 1.0 });
        // set opengl blending to allow for transparency in textures
        gl.enable(gl.BLEND);
        gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);

        try bg.draw();
        try snake.draw();
        try foodItem.draw();
        try gameUI.draw();
        try gameSplash.draw();

        window.swapBuffers();
    }
}
