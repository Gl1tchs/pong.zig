const std = @import("std");
const rl = @import("raylib");

const screenWidth = 800;
const screenHeight = 450;

const halfScreenWidth = screenWidth / 2;
const halfScreenHeight = screenHeight / 2;

const BoundingBox = struct {
    top: f32,
    bottom: f32,
    left: f32,
    right: f32,
};

const Paddle = struct {
    position: rl.Vector2 = rl.Vector2{ .x = 0.0, .y = 0.0 },
    yVelocity: f32 = 0.0,

    const width: i32 = 10;
    const height: i32 = 50;
    const xPadding: i32 = 20;
    const yPadding: i32 = 20;

    fn init(xPos: f32, yPos: f32) Paddle {
        return Paddle{
            .position = rl.Vector2.init(xPos, yPos),
            .yVelocity = 0.0,
        };
    }

    fn getBoundingBox(self: Paddle) BoundingBox {
        return BoundingBox{
            .top = self.position.y + Paddle.height,
            .bottom = self.position.y,
            .left = self.position.x,
            .right = self.position.x + Paddle.width,
        };
    }

    fn doesBallIntersect(self: Paddle, pos: rl.Vector2) bool {
        const box = self.getBoundingBox();
        return pos.x > box.left and pos.x < box.right and pos.y > box.bottom and pos.y < box.top;
    }

    fn draw(self: Paddle) void {
        rl.drawRectangle(@intFromFloat(self.position.x), @intFromFloat(self.position.y), Paddle.width, Paddle.height, rl.Color.white);
    }

    fn update(self: *Paddle) void {
        const expectedTopBorderPos = self.position.y + self.yVelocity;
        const expectedBottomBorderPos = (self.position.y + Paddle.height) + self.yVelocity;

        if (expectedTopBorderPos <= Paddle.yPadding) {
            self.position.y = Paddle.yPadding;
        } else if (expectedBottomBorderPos >= screenHeight - Paddle.yPadding) {
            self.position.y = screenHeight - Paddle.height - Paddle.yPadding;
        } else {
            // process the movement if we are not in corners
            self.position.y += self.yVelocity;
        }

        self.yVelocity = 0;
    }
};

const BallState = enum {
    None,
    ReflectedFromPaddle,
    ReflectedFromWall,
    LeftPaddleWins,
    RightPaddleWins,
};

const Ball = struct {
    position: rl.Vector2 = rl.Vector2{ .x = 0.0, .y = 0.0 },
    velocity: rl.Vector2 = rl.Vector2{ .x = 0.0, .y = 0.0 },

    const radius: i32 = 5;

    fn init(initial_position: rl.Vector2, initial_velocity: rl.Vector2) Ball {
        return Ball{ .position = initial_position, .velocity = initial_velocity };
    }

    fn draw(self: Ball) void {
        rl.drawCircle(@intFromFloat(self.position.x), @intFromFloat(self.position.y), Ball.radius, rl.Color.white);
    }

    /// returns winning paddle type if any
    fn update(self: *Ball, paddle_l: Paddle, paddle_r: Paddle) BallState {
        const expectedPosition = self.position.add(self.velocity);

        var ret: BallState = .None;

        // border checks
        if (expectedPosition.x > screenWidth) {
            ret = .LeftPaddleWins;
        } else if (expectedPosition.x < 0) {
            ret = .RightPaddleWins;
        } else if (paddle_l.doesBallIntersect(expectedPosition) or paddle_r.doesBallIntersect(expectedPosition)) {
            self.velocity = self.velocity.negate();
            self.position = self.position.add(self.velocity);

            ret = .ReflectedFromPaddle;
        } else if (expectedPosition.y > screenHeight) {
            self.position.y = screenHeight;
            self.velocity.y = -self.velocity.y;

            ret = .ReflectedFromWall;
        } else if (expectedPosition.y < 0) {
            self.position.y = 0;
            self.velocity.y = -self.velocity.y;

            ret = .ReflectedFromWall;
        } else {
            self.position = expectedPosition;
        }

        return ret;
    }
};

var paddleL = Paddle{};
var paddleR = Paddle{};
var ball = Ball{};

var ballState: BallState = .None;

fn initGame() void {
    ballState = .None;

    paddleL = Paddle.init(Paddle.xPadding, halfScreenHeight);
    paddleR = Paddle.init(screenWidth - 2 * Paddle.xPadding, halfScreenHeight);

    const screenCenter = rl.Vector2.init(halfScreenWidth, halfScreenHeight);
    const initialVelocity = rl.Vector2.init(-5, 5);

    ball = Ball.init(screenCenter, initialVelocity);
}

pub fn main() anyerror!void {
    rl.initWindow(screenWidth, screenHeight, "pong.zig");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    initGame();

    while (!rl.windowShouldClose()) {
        // paddle_l movement
        if (rl.isKeyDown(rl.KeyboardKey.key_w)) {
            paddleL.yVelocity = -5;
        }
        if (rl.isKeyDown(rl.KeyboardKey.key_s)) {
            paddleL.yVelocity = 5;
        }

        // paddle_r movement
        if (rl.isKeyDown(rl.KeyboardKey.key_up)) {
            paddleR.yVelocity = -5;
        }
        if (rl.isKeyDown(rl.KeyboardKey.key_down)) {
            paddleR.yVelocity = 5;
        }

        if (ballState != .LeftPaddleWins or ballState != .RightPaddleWins) {
            paddleL.update();
            paddleR.update();

            ballState = ball.update(paddleL, paddleR);
        }

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.black);

        paddleL.draw();
        paddleR.draw();

        ball.draw();

        if (ballState == .LeftPaddleWins or ballState == .RightPaddleWins) {
            const text = "Game Over! Press Space to restart the game.";
            const textWidth = rl.measureText(text, 20);

            rl.drawText(text, @divFloor((screenWidth - textWidth), 2), halfScreenHeight - 20, 20, rl.Color.light_gray);

            // restart the game
            if (rl.isKeyDown(rl.KeyboardKey.key_space)) {
                initGame();
            }
        }
    }
}
