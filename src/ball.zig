const rl = @import("raylib");
const globals = @import("globals.zig");

const Paddle = @import("paddle.zig").Paddle;

pub const BallState = enum {
    None,
    ReflectedFromPaddle,
    ReflectedFromWall,
    GameOver,
};

pub const Ball = struct {
    position: rl.Vector2 = rl.Vector2{ .x = 0.0, .y = 0.0 },
    velocity: rl.Vector2 = rl.Vector2{ .x = 0.0, .y = 0.0 },

    const radius: i32 = 5;

    pub fn init(initial_position: rl.Vector2, initial_velocity: rl.Vector2) Ball {
        return Ball{ .position = initial_position, .velocity = initial_velocity };
    }

    pub fn draw(self: Ball) void {
        rl.drawCircle(@intFromFloat(self.position.x), @intFromFloat(self.position.y), Ball.radius, rl.Color.white);
    }

    pub fn update(self: *Ball, paddle_l: Paddle, paddle_r: Paddle) BallState {
        const expectedPosition = self.position.add(self.velocity);

        var ret: BallState = .None;

        // border checks
        if (expectedPosition.x > globals.screenWidth) {
            ret = .GameOver;
        } else if (expectedPosition.x < 0) {
            ret = .GameOver;
        } else if (paddle_l.doesBallIntersect(expectedPosition) or paddle_r.doesBallIntersect(expectedPosition)) {
            self.velocity = self.velocity.negate();
            self.position = self.position.add(self.velocity);

            ret = .ReflectedFromPaddle;
        } else if (expectedPosition.y > globals.screenHeight) {
            self.position.y = globals.screenHeight;
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
