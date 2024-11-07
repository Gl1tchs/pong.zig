const std = @import("std");
const rl = @import("raylib");
const ball = @import("ball.zig");
const globals = @import("globals.zig");

const Paddle = @import("paddle.zig").Paddle;
const Ball = ball.Ball;
const BallState = ball.BallState;

const GameState = struct {
    paddleL: Paddle = Paddle{},
    paddleR: Paddle = Paddle{},
    ball: Ball = Ball{},
    score: i32 = 0,
    ballState: BallState = .None,

    fn init(self: *GameState) anyerror!void {
        self.score = 0;
        self.ballState = .None;

        self.paddleL = Paddle.init(Paddle.xPadding, globals.halfScreenHeight);
        self.paddleR = Paddle.init(globals.screenWidth - 2 * Paddle.xPadding, globals.halfScreenHeight);

        const screenCenter = rl.Vector2.init(globals.halfScreenWidth, globals.halfScreenHeight);

        const rand = std.crypto.random;
        const initialVelocity = rl.Vector2.init(if (rand.boolean()) 5 else -5, if (rand.boolean()) 5 else -5);

        self.ball = Ball.init(screenCenter, initialVelocity);
    }
};

pub fn main() anyerror!void {
    rl.initWindow(globals.screenWidth, globals.screenHeight, "pong.zig");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    var state = GameState{};
    try state.init();

    while (!rl.windowShouldClose()) {
        // paddle_l movement
        if (rl.isKeyDown(rl.KeyboardKey.key_w)) {
            state.paddleL.yVelocity = -5;
        }
        if (rl.isKeyDown(rl.KeyboardKey.key_s)) {
            state.paddleL.yVelocity = 5;
        }

        // paddle_r movement
        if (rl.isKeyDown(rl.KeyboardKey.key_up)) {
            state.paddleR.yVelocity = -5;
        }
        if (rl.isKeyDown(rl.KeyboardKey.key_down)) {
            state.paddleR.yVelocity = 5;
        }

        if (state.ballState != .GameOver) {
            state.paddleL.update();
            state.paddleR.update();

            state.ballState = state.ball.update(state.paddleL, state.paddleR);

            if (state.ballState == .ReflectedFromPaddle) {
                state.score += 1;
            }
        }

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.black);

        // draw score text
        {
            const allocator = std.heap.page_allocator;

            const scoreTextArray = try std.fmt.allocPrint(allocator, "Score: {}", .{state.score});
            errdefer allocator.free(scoreTextArray);

            const scoreText = try allocator.dupeZ(u8, scoreTextArray);
            errdefer allocator.free(scoreText);

            const scoreTextWidth = rl.measureText(scoreText[0..], 20);
            rl.drawText(scoreText[0..], @divFloor((globals.screenWidth - scoreTextWidth), 2), 20, 20, rl.Color.light_gray);
        }

        state.paddleL.draw();
        state.paddleR.draw();

        state.ball.draw();

        if (state.ballState == .GameOver) {
            const text = "Game Over! Press Space to restart the game.";
            const textWidth = rl.measureText(text, 20);

            rl.drawText(text, @divFloor((globals.screenWidth - textWidth), 2), globals.halfScreenHeight - 20, 20, rl.Color.light_gray);

            // restart the game
            if (rl.isKeyDown(rl.KeyboardKey.key_space)) {
                try state.init();
            }
        }
    }
}
