const gl = @import("zopengl");

pub fn dotProductVec2(a: [2]gl.Float, b: [2]gl.Float) f64 {
    return a[0] * b[0] + a[1] * b[1];
}

pub fn dotProductVec3(a: [3]gl.Float, b: [3]gl.Float) f64 {
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2];
}
