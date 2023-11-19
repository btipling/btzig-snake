const std = @import("std");
const state = @import("../state.zig");
const zgui = @import("zgui");
const glfw = @import("zglfw");

pub fn draw(gameState: *state.State, window: *glfw.Window) !void {
    const fb_size = window.getFramebufferSize();
    const w: u32 = @intCast(fb_size[0]);
    const h: u32 = @intCast(fb_size[1]);
    const xPos: f32 = @as(f32, @floatFromInt(fb_size[0])) - 350.0;
    const yPos: f32 = @as(f32, @floatFromInt(fb_size[1])) - 125.0;
    zgui.backend.newFrame(w, h);
    zgui.setNextWindowPos(.{ .x = xPos, .y = yPos, .cond = .always });
    zgui.setNextWindowSize(.{
        .w = 300,
        .h = 40,
    });
    zgui.setNextItemWidth(-1);
    const style = zgui.getStyle();
    var window_bg = style.getColor(.window_bg);
    window_bg = .{ 1.00, 1.00, 1.00, 0.90 };
    style.setColor(.window_bg, window_bg);
    var text_color = style.getColor(.text);
    // set text color a gray color
    text_color = .{ 0.38, 0.58, 0.68, 1.00 };
    style.setColor(.text, text_color);
    if (zgui.begin("Hello, world!", .{
        .flags = .{
            .no_title_bar = true,
            .no_resize = true,
            .no_scrollbar = true,
            .no_collapse = true,
        },
    })) {
        zgui.text("Score: {d}", .{gameState.score});
    }
    zgui.end();
    zgui.backend.draw();
}
