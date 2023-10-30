const gl = @import("zopengl");
// | sx 0  0 |
// | 0  sy 0 |
// | 0  0  1 |
// {
//   sx, 0, 0,
//   0, sy, 0,
//   0, 0, 1
// }
// | 1 0  tx |
// | 0  1 ty |
// | 0  0  1 |
// {
//   1, 0, tx,
//   0, 1, ty,
//   0, 0, 1
// }

pub fn multiplyMat3(a: [9]gl.Float, b: [9]gl.Float) [9]gl.Float {
    var result: [9]gl.Float = undefined;
    for (0..3) |i| {
        for (0..3) |j| {
            var sum: gl.Float = 0;
            for (0..3) |k| {
                sum += a[i * 3 + k] * b[j + k * 3];
            }
            result[i * 3 + j] = sum;
        }
    }
    return result;
}

pub fn scaleMat3(sx: gl.Float, sy: gl.Float) [9]gl.Float {
    return [_]gl.Float{ sx, 0, 0, 0, sy, 0, 0, 0, 1 };
}

pub fn translateMat3(tx: gl.Float, ty: gl.Float) [9]gl.Float {
    return [_]gl.Float{ 1, 0, 0, 0, 1, 0, tx, ty, 1 };
}

pub fn scaleTranslateMat3(vec: [4]gl.Float) [9]gl.Float {
    return multiplyMat3(scaleMat3(vec[0], vec[1]), translateMat3(vec[2], vec[3]));
}

pub fn rotateMat3(angle: gl.Float) [9]gl.Float {
    var c = @import("math").cos(angle);
    var s = @import("math").sin(angle);
    return [_]gl.Float{ c, -s, 0, s, c, 0, 0, 0, 1 };
}
