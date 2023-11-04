const gl = @import("zopengl");

pub const Segment = struct {
    vertices: [8]gl.Float,
    indices: [6]gl.Uint,

    pub fn init() Segment {
        var rv = Segment{
            .vertices = [_]gl.Float{
                0.5,  0.5,
                0.5,  -0.5,
                -0.5, -0.5,
                -0.5, 0.5,
            },
            .indices = [_]gl.Uint{
                0, 1, 3,
                1, 2, 3,
            },
        };
        return rv;
    }
};
