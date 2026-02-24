const std = @import("std");

const Interval = @This();

min: f32,
max: f32,

pub fn empty() Interval {
    return .{
        .min = std.math.floatMax(f32),
        .max = -std.math.floatMax(f32),
    };
}

pub fn universe() Interval {
    return .{
        .min = -std.math.floatMax(f32),
        .max = std.math.floatMax(f32),
    };
}

pub fn size(self: Interval) f32 {
    return self.max - self.min;
}

pub fn contains(self: Interval, x: f32) bool {
    return self.min <= x and x <= self.max;
}

pub fn surrounds(self: Interval, x: f32) bool {
    return self.min < x and x < self.max;
}

pub fn clamp(self: Interval, x: f32) f32 {
    if (x < self.min) {
        return self.min;
    }
    if (x > self.max) {
        return self.max;
    }
    return x;
}
