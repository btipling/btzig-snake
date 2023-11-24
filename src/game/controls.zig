const zglfw = @import("zglfw");
const state = @import("state.zig");

pub fn handleKey(gameState: *state.State, window: *zglfw.Window) !bool {
    // Not supporting multiple keys pressed at the same time just yet.
    if (window.getKey(.escape) == .press) {
        return true;
    }
    if (window.getKey(.q) == .press) {
        return true;
    }
    if (window.getKey(.left) == .press) {
        try state.State.goLeft(gameState);
        return false;
    }
    if (window.getKey(.a) == .press) {
        try state.State.goLeft(gameState);
        return false;
    }
    if (window.getKey(.h) == .press) {
        try state.State.goLeft(gameState);
        return false;
    }
    if (window.getKey(.right) == .press) {
        try state.State.goRight(gameState);
        return false;
    }
    if (window.getKey(.d) == .press) {
        try state.State.goRight(gameState);
        return false;
    }
    if (window.getKey(.l) == .press) {
        try state.State.goRight(gameState);
        return false;
    }
    if (window.getKey(.up) == .press) {
        try state.State.goUp(gameState);
        return false;
    }
    if (window.getKey(.w) == .press) {
        try state.State.goUp(gameState);
        return false;
    }
    if (window.getKey(.k) == .press) {
        try state.State.goUp(gameState);
        return false;
    }
    if (window.getKey(.down) == .press) {
        try state.State.goDown(gameState);
        return false;
    }
    if (window.getKey(.s) == .press) {
        try state.State.goDown(gameState);
        return false;
    }
    if (window.getKey(.j) == .press) {
        try state.State.goDown(gameState);
        return false;
    }
    if (window.getKey(.p) == .press) {
        try state.State.togglePause(gameState);
        return false;
    }

    return false;
}
