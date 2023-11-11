const gl = @import("zopengl");

pub const game_name: [:0]const u8 = "BT Snake";
pub const windows_height: i32 = 1250;
pub const windows_width: i32 = 1250;
pub const initial_speed: gl.Float = 1.0;
pub const initial_start_x: gl.Float = 20.0;
pub const initial_start_y: gl.Float = 20.0;
pub const initial_delay: gl.Uint = 1000;
pub const grid_size: gl.Float = 40.0;
