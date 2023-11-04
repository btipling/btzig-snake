const gl = @import("zopengl");

pub var vertices = [_]gl.Float{
    0.5,  0.5,
    0.5,  -0.5,
    -0.5, -0.5,
    -0.5, 0.5,
};

pub var indices = [_]gl.Uint{
    0, 1, 3,
    1, 2, 3,
};
