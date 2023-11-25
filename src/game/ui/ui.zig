const std = @import("std");
const zgui = @import("zgui");
const glfw = @import("zglfw");
const state = @import("../state.zig");
const segment = @import("../object/segment/segment.zig");

pub const UI = struct {
    state: *state.State,
    window: *glfw.Window,
    demoSnake: [41]state.coordinate,
    segment: segment.Segment,

    pub fn init(gameState: *state.State, window: *glfw.Window, seg: segment.Segment) !UI {
        return UI{
            .state = gameState,
            .window = window,
            .demoSnake = .{
                .{ .x = 4, .y = 5 },
                .{ .x = 5, .y = 5 },
                .{ .x = 6, .y = 5 },
                .{ .x = 6, .y = 4 },
                .{ .x = 6, .y = 3 },
                .{ .x = 5, .y = 3 },
                .{ .x = 4, .y = 3 },
                .{ .x = 3, .y = 3 },
                .{ .x = 2, .y = 3 },
                .{ .x = 1, .y = 3 },
                .{ .x = 1, .y = 2 },
                .{ .x = 1, .y = 1 },
                .{ .x = 2, .y = 1 },
                .{ .x = 3, .y = 1 },
                .{ .x = 4, .y = 1 },
                .{ .x = 5, .y = 1 },
                .{ .x = 6, .y = 1 },
                .{ .x = 7, .y = 1 },
                .{ .x = 8, .y = 1 },
                .{ .x = 9, .y = 1 },
                .{ .x = 10, .y = 1 },
                .{ .x = 11, .y = 1 },
                .{ .x = 12, .y = 1 },
                .{ .x = 13, .y = 1 },
                .{ .x = 14, .y = 1 },
                .{ .x = 15, .y = 1 },
                .{ .x = 16, .y = 1 },
                .{ .x = 17, .y = 1 },
                .{ .x = 18, .y = 1 },
                .{ .x = 19, .y = 1 },
                .{ .x = 19, .y = 2 },
                .{ .x = 19, .y = 3 },
                .{ .x = 18, .y = 3 },
                .{ .x = 17, .y = 3 },
                .{ .x = 16, .y = 3 },
                .{ .x = 15, .y = 3 },
                .{ .x = 14, .y = 3 },
                .{ .x = 14, .y = 4 },
                .{ .x = 14, .y = 5 },
                .{ .x = 15, .y = 5 },
                .{ .x = 16, .y = 5 },
            },
            .segment = seg,
        };
    }

    pub fn draw(self: UI) !void {
        try self.segment.drawDemoSnake(&self.demoSnake, state.Direction.Left);
        try self.drawSidebar();
    }

    fn drawSidebar(self: UI) !void {
        const fb_size = self.window.getFramebufferSize();
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
            zgui.text("Score: {d}", .{self.state.score});
        }
        zgui.end();
        zgui.backend.draw();
    }
};
