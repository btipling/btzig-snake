const std = @import("std");
const sdl = @import("zsdl");
const gl = @import("zopengl");
const cfg = @import("config.zig");
const segment = @import("object/segment/segment.zig");
const food = @import("object/food/food.zig");
const grid = @import("grid.zig");
const state = @import("state.zig");
const controls = @import("controls.zig");

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
    var foodItem = try food.Food.init();
    var gameGrid = grid.Grid.init(cfg.grid_size);

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var gameState = try state.State.init(
        gameGrid,
        cfg.initial_speed,
        cfg.initial_delay,
        cfg.initial_start_x,
        cfg.initial_start_y,
        allocator,
    );
    state.State.generateFoodPosition(&gameState);
    var lastTick = std.time.milliTimestamp();
    main_loop: while (true) {
        var event: sdl.Event = undefined;
        while (sdl.pollEvent(&event)) {
            if (event.type == .quit) {
                break :main_loop;
            } else if (event.type == .keydown) {
                const quit = try controls.handleKey(&gameState, event.key.keysym.sym);
                if (quit) {
                    break :main_loop;
                }
            }
        }
        if (std.time.milliTimestamp() - lastTick > gameState.delay) {
            try state.State.move(&gameState);
            lastTick = std.time.milliTimestamp();
        }
        gl.clearBufferfv(gl.COLOR, 0, &[_]f32{ 0.2, 0.4, 0.8, 1.0 });
        for (gameState.segments.items) |coords| {
            var posX: gl.Float = try gameGrid.indexToGridPosition(coords.x);
            var posY: gl.Float = try gameGrid.indexToGridPosition(coords.y);
            try seg.draw(posX, posY, gameState.grid.scaleFactor);
        }
        try foodItem.draw(gameState.foodX, gameState.foodY, gameState.grid.scaleFactor);
        sdl.gl.swapWindow(window);
    }
}
