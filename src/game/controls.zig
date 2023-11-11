const sdl = @import("zsdl");
const state = @import("state.zig");

pub fn handleKey(gameState: *state.State, keyCode: sdl.Keycode) !bool {
    switch (keyCode) {
        .q => return true,
        .escape => return true,
        .left => {
            try state.State.goLeft(gameState);
        },
        .a => {
            try state.State.goLeft(gameState);
        },
        .h => {
            try state.State.goLeft(gameState);
        },
        .right => {
            try state.State.goRight(gameState);
        },
        .d => {
            try state.State.goRight(gameState);
        },
        .l => {
            try state.State.goRight(gameState);
        },
        .up => {
            try state.State.goUp(gameState);
        },
        .w => {
            try state.State.goUp(gameState);
        },
        .k => {
            try state.State.goUp(gameState);
        },
        .down => {
            try state.State.goDown(gameState);
        },
        .s => {
            try state.State.goDown(gameState);
        },
        .j => {
            try state.State.goDown(gameState);
        },
        .p => {
            state.State.togglePause(gameState);
        },
        else => {},
    }
    return false;
}
