const std = @import("std");
const gl = @import("zopengl");
const zstbi = @import("zstbi");
const glutils = @import("../../gl/gl.zig");
const state = @import("../../state.zig");
const head = @import("../head/head.zig");

pub const SegmentErr = error{Error};
const objectName = "segment";

// zig fmt: off
const bankUpLeftVertices: [16]gl.Float = [_]gl.Float{
                // positions   // texture coords
                1,  1,          0.5, 1,
                1,  -1,         0.5, 0,
                -1, -1,         0.75, 0,
                -1, 1,          0.75, 1,
};

const horizontalVertices: [16]gl.Float = [_]gl.Float{
                // positions   // texture coords
                1,  1,          0.5, 1,
                1,  -1,         0.5, 0,
                -1, -1,         0.25, 0,
                -1, 1,          0.25, 1,
};

const verticalVertices: [16]gl.Float = [_]gl.Float{
                // positions   // texture coords
                // ◳            // ◱
                1,  1,          0.25, 1.0,
                // ◲           // ◲       
                1,  -1,         0.5, 1.0,
                // ◱           // ◳
                -1, -1,         0.5, 0.0,
                // ◰           // ◰  
                -1, 1,          0.25, 0.0,
};

const bankDownRightVertices: [16]gl.Float = [_]gl.Float{
                // positions   // texture coords
                 1,   1,         0.25, 1,
                 1,  -1,         0.25, 0,
                -1,  -1,         0.00, 0,
                -1,   1,         0.00, 1,
};

const bankDownLeftVertices = verticalVertices;

const bankRightDownVertices = horizontalVertices;


const downTailVertices: [16]gl.Float = [_]gl.Float{
                // positions   // texture coords
                // ◳            // ◱   
                1,  1,          0.75, 1.0,
                // ◲           // ◲   
                1,  -1,         1.0, 1.0,
                // ◱           // ◳
                -1, -1,         1.0, 0.0,
                // ◰           // ◰ 
                -1, 1,          0.75, 0.0,
};

const upTailVertices: [16]gl.Float = [_]gl.Float{
                // positions   // texture coords
                // ◳           // ◲   
                1,  1,          1.0, 1.0,
                // ◲           // ◱ 
                1, -1,          0.75, 1.0,
                // ◱           // ◰  
                -1, -1,         0.75, 0.0,
                // ◰           // ◳ 
                -1, 1,          1.0, 0.0,
};

const rightTailVertices: [16]gl.Float = [_]gl.Float{
                // positions   // texture coords
                // ◳           // ◳    
                1,  1,          1.0, 0.0,
                // ◲           // ◲ 
                1,  -1,         1.0, 1.0,
                // ◱           // ◱  
                -1, -1,         0.75, 1.0,
                // ◰           // ◰ 
                -1, 1,          0.75, 0.0
};



const leftTailVertices: [16]gl.Float = [_]gl.Float{
                // positions   // texture coords
                // ◳           // ◰   
                1,  1,         0.75, 0.0,
                // ◲           // ◱
                1,  -1,         0.75, 1.0,
                // ◱           // ◲ 
                -1, -1,         1.0, 1.0,
                // ◰           // ◳ 
                -1, 1,          1.0, 0.0,
};
// zig fmt: on

const num_vaos: comptime_int = 10;

pub const Segment = struct {
    state: *state.State,
    indices: [6]gl.Uint,
    VAOs: [num_vaos]gl.Uint,
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
            .VAOs = [_]gl.Uint{undefined} ** num_vaos,
            .texture = undefined,
            .shaderProgram = undefined,
            .snakeHead = snakeHead,
        };
        const combinedVertices = [_][16]gl.Float{
            bankUpLeftVertices,
            bankDownLeftVertices,
            horizontalVertices,
            verticalVertices,
            bankRightDownVertices,
            bankDownRightVertices,
            downTailVertices,
            upTailVertices,
            rightTailVertices,
            leftTailVertices,
        };
        for (combinedVertices, 0..) |vertices, i| {
            const VAO = try glutils.initVAO(objectName);
            _ = try glutils.initVBO(objectName);
            _ = try rv.initEBO();
            try initData(vertices);
            rv.VAOs[i] = VAO;
        }
        rv.texture = try initTexture();
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

    fn initTexture() !gl.Uint {
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

    pub fn drawDemoSnake(self: Segment, segments: []const state.coordinate, direction: state.Direction, offGrid: ?[2]gl.Float) !void {
        const coords = segments[0];
        try self.snakeHead.drawAt(coords.x, coords.y, direction, offGrid);
        return self.drawSegments(segments, offGrid);
    }

    pub fn drawTail(self: Segment, segments: []const state.coordinate, offGrid: ?[2]gl.Float) !void {
        if (segments.len < 2) {
            std.debug.print("tail draw error: segments.len < 2\n", .{});
            return;
        }
        const tail = segments[segments.len - 1];
        const bef = segments[segments.len - 2];
        if (bef.y + 1 == tail.y) {
            // if bef y is less than tail y then bef y + 1 is equal and tail is going down
            try self.drawSegment(self.VAOs[6], tail.x, tail.y, offGrid);
            return;
        }
        if (bef.y - 1 == tail.y) {
            // if bef y is greater than tail y then bef y - 1 is equal and tail is going up
            try self.drawSegment(self.VAOs[7], tail.x, tail.y, offGrid);
            return;
        }
        if (bef.x + 1 == tail.x) {
            try self.drawSegment(self.VAOs[8], tail.x, tail.y, offGrid);
            return;
        }
        try self.drawSegment(self.VAOs[9], tail.x, tail.y, offGrid);
    }

    pub fn drawSegments(self: Segment, segments: []const state.coordinate, offGrid: ?[2]gl.Float) !void {
        for (segments[0..], 0..) |coords, i| {
            if (i == 0) {
                continue;
            }
            if (i == segments.len - 1) {
                try self.drawTail(segments, offGrid);
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
            if (isSegmentBankingUpLeft(segments, i)) {
                try self.drawSegment(self.VAOs[0], posX, posY, offGrid);
                continue;
            }
            if (isSegmentBankingDownLeft(segments, i)) {
                try self.drawSegment(self.VAOs[1], posX, posY, offGrid);
                continue;
            }
            if (isSegmentBankingRightDown(segments, i)) {
                try self.drawSegment(self.VAOs[4], posX, posY, offGrid);
                continue;
            }
            if (isSegmentBankingDownRight(segments, i)) {
                try self.drawSegment(self.VAOs[5], posX, posY, offGrid);
                continue;
            }
            try self.drawSegment(self.VAOs[2], posX, posY, offGrid);
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

    fn isSegmentBankingUpLeft(segments: []const state.coordinate, index: usize) bool {
        if (index == 0) {
            // index is head
            return false;
        }
        if (segments.len == index + 1) {
            // index is tail
            return false;
        }
        const bef = segments[index - 1];
        const cur = segments[index];
        const aft = segments[index + 1];
        // grid origin top left is 0, 0, arrow represents before
        //
        // before
        // ←--| current
        //    | after
        //
        // before is left at same y
        if (bef.x + 1 == cur.x and bef.y == cur.y) {
            // and after is below at same x
            if (aft.x == cur.x and aft.y - 1 == cur.y) {
                return true;
            }
        }
        // or
        //
        // after
        // ---| current
        //    ↓ before
        //
        // before is below at same x
        if (bef.x == cur.x and bef.y - 1 == cur.y) {
            // and after is left at same y:
            if (aft.x + 1 == cur.x and aft.y == cur.y) {
                return true;
            }
        }
        return false;
    }

    fn isSegmentBankingDownLeft(segments: []const state.coordinate, index: usize) bool {
        if (index == 0) {
            // index is head
            return false;
        }
        if (segments.len == index + 1) {
            // index is tail
            return false;
        }
        const bef = segments[index - 1];
        const cur = segments[index];
        const aft = segments[index + 1];
        // grid origin top left is 0, 0, arrow represents before
        //
        //    | after
        // ←--| current
        // before
        //
        // before is left at same y
        if (bef.x + 1 == cur.x and bef.y == cur.y) {
            // and after is above at same x
            if (aft.x == cur.x and aft.y + 1 == cur.y) {
                return true;
            }
        }
        // or
        //
        //    ↑ before
        // ---| current
        // after
        //
        // before is above at same x
        if (bef.x == cur.x and bef.y + 1 == cur.y) {
            // and after is left at same y:
            if (aft.x + 1 == cur.x and aft.y == cur.y) {
                return true;
            }
        }
        return false;
    }

    fn isSegmentBankingRightDown(segments: []const state.coordinate, index: usize) bool {
        if (index == 0) {
            // index is head
            return false;
        }
        if (segments.len == index + 1) {
            // index is tail
            return false;
        }
        const bef = segments[index - 1];
        const cur = segments[index];
        const aft = segments[index + 1];
        // grid origin top left is 0, 0, arrow represents before
        //
        //          after
        // current |---
        // before  ↓
        //
        // before below at same x
        if (bef.x == cur.x and bef.y - 1 == cur.y) {
            // and after is right at same y
            if (aft.x - 1 == cur.x and aft.y == cur.y) {
                return true;
            }
        }
        // or
        //
        //          before
        // current |--→
        // after   |
        //
        // before is right at same y
        if (bef.x - 1 == cur.x and bef.y == cur.y) {
            // and after is below at same x:
            if (aft.x == cur.x and aft.y - 1 == cur.y) {
                return true;
            }
        }
        return false;
    }

    fn isSegmentBankingDownRight(segments: []const state.coordinate, index: usize) bool {
        if (index == 0) {
            // index is head
            return false;
        }
        if (segments.len == index + 1) {
            // index is tail
            return false;
        }
        const bef = segments[index - 1];
        const cur = segments[index];
        const aft = segments[index + 1];
        // grid origin top left is 0, 0, arrow represents before
        //
        //
        // before  ↑
        // current |---
        //          after
        //
        // before above at same x
        if (bef.x == cur.x and bef.y + 1 == cur.y) {
            // and after is right at same y
            if (aft.x - 1 == cur.x and aft.y == cur.y) {
                return true;
            }
        }
        // or
        //
        //
        // after   |
        // current |--→
        //          before
        //
        // before is right at same y
        if (bef.x - 1 == cur.x and bef.y == cur.y) {
            // and after is above at same x:
            if (aft.x == cur.x and aft.y + 1 == cur.y) {
                return true;
            }
        }
        return false;
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
