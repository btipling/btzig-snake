const sdl = @import("zsdl");
const state = @import("state.zig");

pub fn handleKey(gameState: *state.State, keyCode: sdl.Keycode) !bool {
    switch (keyCode) {
        .q => return true,
        .escape => return true,
        .left => {
            try state.State.moveLeft(gameState);
        },
        .a => {
            try state.State.moveLeft(gameState);
        },
        .h => {
            try state.State.moveLeft(gameState);
        },
        .right => {
            try state.State.moveRight(gameState);
        },
        .d => {
            try state.State.moveRight(gameState);
        },
        .l => {
            try state.State.moveRight(gameState);
        },
        .up => {
            try state.State.moveUp(gameState);
        },
        .w => {
            try state.State.moveUp(gameState);
        },
        .k => {
            try state.State.moveUp(gameState);
        },
        .down => {
            try state.State.moveDown(gameState);
        },
        .s => {
            try state.State.moveDown(gameState);
        },
        .j => {
            try state.State.moveDown(gameState);
        },
        else => {},
    }
    return false;
}
