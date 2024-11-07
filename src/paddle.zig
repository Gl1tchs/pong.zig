const rl = @import("raylib");
const globals = @import("globals.zig");

const BoundingBox = struct {
    top: f32,
    bottom: f32,
    left: f32,
    right: f32,
};

pub const Paddle = struct {
    position: rl.Vector2 = rl.Vector2{ .x = 0.0, .y = 0.0 },
    yVelocity: f32 = 0.0,

    pub const width: i32 = 10;
    pub const height: i32 = 50;
    pub const xPadding: i32 = 20;
    pub const yPadding: i32 = 20;

    pub fn init(xPos: f32, yPos: f32) Paddle {
        return Paddle{
            .position = rl.Vector2.init(xPos, yPos),
            .yVelocity = 0.0,
        };
    }

    pub fn getBoundingBox(self: Paddle) BoundingBox {
        return BoundingBox{
            .top = self.position.y + Paddle.height,
            .bottom = self.position.y,
            .left = self.position.x,
            .right = self.position.x + Paddle.width,
        };
    }

    pub fn doesBallIntersect(self: Paddle, pos: rl.Vector2) bool {
        const box = self.getBoundingBox();
        return pos.x > box.left and pos.x < box.right and pos.y > box.bottom and pos.y < box.top;
    }

    pub fn draw(self: Paddle) void {
        rl.drawRectangle(@intFromFloat(self.position.x), @intFromFloat(self.position.y), Paddle.width, Paddle.height, rl.Color.white);
    }

    pub fn update(self: *Paddle) void {
        const expectedTopBorderPos = self.position.y + self.yVelocity;
        const expectedBottomBorderPos = (self.position.y + Paddle.height) + self.yVelocity;

        if (expectedTopBorderPos <= Paddle.yPadding) {
            self.position.y = Paddle.yPadding;
        } else if (expectedBottomBorderPos >= globals.screenHeight - Paddle.yPadding) {
            self.position.y = globals.screenHeight - Paddle.height - Paddle.yPadding;
        } else {
            // process the movement if we are not in corners
            self.position.y += self.yVelocity;
        }

        self.yVelocity = 0;
    }
};
