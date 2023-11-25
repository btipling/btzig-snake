const std = @import("std");
const gl = @import("zopengl");
const zstbi = @import("zstbi");
const glutils = @import("../../gl/gl.zig");
const state = @import("../../state.zig");
const head = @import("../head/head.zig");

pub const SegmentErr = error{Error};
const objectName = "segment";

// zig fmt: off
const sideWaysVertices: [16]gl.Float = [_]gl.Float{
                // positions   // texture coords
                1,  1,          0.5, 1,
                1,  -1,         0.5, 0,
                -1, -1,         1, 0,
                -1, 1,          1, 1,
};

const leftVertices: [16]gl.Float = [_]gl.Float{
                // positions   // texture coords
                1,  1,          1, 1,
                1,  -1,         1, 0,
                -1, -1,         0.5, 0,
                -1, 1,          0.5, 1,
};

const horizontalVertices: [16]gl.Float = [_]gl.Float{
                // positions   // texture coords
                1,  1,          0.5, 1,
                1,  -1,         0.5, 0,
                -1, -1,         0, 0,
                -1, 1,          0, 1,
};

const verticalVertices: [16]gl.Float = [_]gl.Float{
                // positions   // texture coords
                // ◳            // ◰
                1,  1,          0.0, 1.0,
                // ◲           // ◳      
                1,  -1,         0.5, 1.0,
                // ◱           // ◲
                -1, -1,         0.5, 0.0,
                // ◰           // ◱   
                -1, 1,          0.0, 0.0,
};
// zig fmt: on

pub const Segment = struct {
    state: *state.State,
    indices: [6]gl.Uint,
    VAOs: [4]gl.Uint,
    texture: gl.Uint,
    shaderProgram: gl.Uint,
    snakeHead: head.Head,

    pub fn init(gameState: *state.State) !Segment {
        const snakeHead = try head.Head.init(gameState);
        var rv = Segment{
            .state = gameState,
            .indices = [_]gl.Uint{
                0, 1, 3,
                1, 2, 3,
            },
            .VAOs = [_]gl.Uint{
                undefined,
                undefined,
                undefined,
                undefined,
            },
            .texture = undefined,
            .shaderProgram = undefined,
            .snakeHead = snakeHead,
        };
        const combinedVertices = [4][16]gl.Float{ sideWaysVertices, leftVertices, horizontalVertices, verticalVertices };
        for (combinedVertices, 0..) |vertices, i| {
            const VAO = try glutils.initVAO(objectName);
            _ = try glutils.initVBO(objectName);
            _ = try rv.initEBO();
            try initData(vertices);
            rv.VAOs[i] = VAO;
        }
        rv.texture = try rv.initTexture();
        const vertexShader = try glutils.initVertexShader(@embedFile("shaders/segment.vs"), objectName);
        const fragmentShader = try glutils.initFragmentShader(@embedFile("shaders/segment.fs"), objectName);
        rv.shaderProgram = try glutils.initProgram("BACKGROUND", &[_]gl.Uint{ vertexShader, fragmentShader });
        return rv;
    }

    fn initEBO(self: Segment) !gl.Uint {
        const EBO = glutils.initEBO(objectName);
        gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, self.indices.len * @sizeOf(gl.Int), &self.indices, gl.STATIC_DRAW);
        const e = gl.getError();
        if (e != gl.NO_ERROR) {
            std.debug.print("{s} buffer data error: {d}\n", .{ objectName, e });
            return SegmentErr.Error;
        }
        return EBO;
    }

    fn initTexture(self: Segment) !gl.Uint {
        _ = self;
        var texture: gl.Uint = undefined;
        var e: gl.Uint = 0;
        gl.genTextures(1, &texture);
        gl.bindTexture(gl.TEXTURE_2D, texture);

        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);

        const snake_ext: [:0]const u8 = @embedFile("../../assets/textures/snake_extended.png");
        var image = try zstbi.Image.loadFromMemory(snake_ext, 4);
        defer image.deinit();
        std.debug.print("loaded image {d}x{d}\n", .{ image.width, image.height });

        const width: gl.Int = @as(gl.Int, @intCast(image.width));
        const height: gl.Int = @as(gl.Int, @intCast(image.height));
        const imageData: *const anyopaque = image.data.ptr;
        gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, width, height, 0, gl.RGBA, gl.UNSIGNED_BYTE, imageData);
        e = gl.getError();
        if (e != gl.NO_ERROR) {
            std.debug.print("error: {d}\n", .{e});
            return SegmentErr.Error;
        }
        gl.generateMipmap(gl.TEXTURE_2D);
        e = gl.getError();
        if (e != gl.NO_ERROR) {
            std.debug.print("error: {d}\n", .{e});
            return SegmentErr.Error;
        }
        return texture;
    }

    fn initData(vertices: [16]gl.Float) !void {
        gl.bufferData(gl.ARRAY_BUFFER, vertices.len * @sizeOf(gl.Float), &vertices, gl.STATIC_DRAW);
        gl.vertexAttribPointer(0, 2, gl.FLOAT, gl.FALSE, 4 * @sizeOf(gl.Float), null);
        gl.enableVertexAttribArray(0);
        var e = gl.getError();
        if (e != gl.NO_ERROR) {
            std.debug.print("error: {d}\n", .{e});
            return SegmentErr.Error;
        }
        gl.vertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, 4 * @sizeOf(gl.Float), @as(*anyopaque, @ptrFromInt(2 * @sizeOf(gl.Float))));
        gl.enableVertexAttribArray(1);
        e = gl.getError();
        if (e != gl.NO_ERROR) {
            std.debug.print("error: {d}\n", .{e});
            return SegmentErr.Error;
        }
    }

    fn initShaderProgram(self: Segment) !gl.Uint {
        return glutils.initProgram("SEGMENT", &[_]gl.Uint{ self.vertexShader, self.fragmentShader });
    }

    pub fn draw(self: Segment) !void {
        try self.snakeHead.draw();
        return self.drawSegments(self.state.segments.items, null);
    }

    pub fn drawDemoSnake(self: Segment, segments: []const state.coordinate, direction: state.Direction) !void {
        const coords = segments[0];
        const offGrid = [2]gl.Float{ 1.3, -0.025 };
        try self.snakeHead.drawAt(coords.x, coords.y, direction, offGrid);
        return self.drawSegments(segments, offGrid);
    }

    pub fn drawSegments(self: Segment, segments: []const state.coordinate, offGrid: ?[2]gl.Float) !void {
        for (segments[0..], 0..) |coords, i| {
            if (i == 0) {
                continue;
            }
            const posX: gl.Float = try self.state.grid.indexToGridPosition(coords.x);
            const posY: gl.Float = try self.state.grid.indexToGridPosition(coords.y);
            if (isSegmentAtIndexHorizontal(segments, i)) {
                try self.drawSegment(self.VAOs[2], posX, posY, offGrid);
                continue;
            }
            if (isSegmentAtIndexVertical(segments, i)) {
                try self.drawSegment(self.VAOs[3], posX, posY, offGrid);
                continue;
            }
            try self.drawSegment(self.VAOs[i % 2], posX, posY, offGrid);
        }
    }

    fn isSegmentAtIndexVertical(segments: []const state.coordinate, index: usize) bool {
        var sidewaysNeighbors: u2 = 0;
        if (segments.len == index + 1) {
            sidewaysNeighbors += 1;
        } else if (segments[index].x == segments[index + 1].x) {
            sidewaysNeighbors += 1;
        }
        if (index == 0) {
            sidewaysNeighbors += 1;
        } else if (segments[index].x == segments[index - 1].x) {
            sidewaysNeighbors += 1;
        }
        return sidewaysNeighbors == 2;
    }

    fn isSegmentAtIndexHorizontal(segments: []const state.coordinate, index: usize) bool {
        var sidewaysNeighbors: u2 = 0;
        if (segments.len == index + 1) {
            sidewaysNeighbors += 1;
        } else if (segments[index].y == segments[index + 1].y) {
            sidewaysNeighbors += 1;
        }
        if (index == 0) {
            sidewaysNeighbors += 1;
        } else if (segments[index].y == segments[index - 1].y) {
            sidewaysNeighbors += 1;
        }
        return sidewaysNeighbors == 2;
    }

    fn drawSegment(self: Segment, VAO: gl.Uint, posX: gl.Float, posY: gl.Float, offGrid: ?[2]gl.Float) !void {
        var transV = self.state.grid.objectTransform(posX, posY);
        if (offGrid) |offset| {
            transV[2] += offset[0];
            transV[3] += offset[1];
        }
        try glutils.draw(self.shaderProgram, VAO, self.texture, &self.indices, transV);
    }
};
