const Vec3 = @import("Vec3.zig");

const Ray = @This();

origin: Vec3,
dir: Vec3,

fn at(self: Ray, t: f64) Vec3 {
    return self.origin + t * self.dir;
}
