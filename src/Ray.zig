const Vec3 = @import("Vec3.zig");

const Ray = @This();

origin: Vec3,
dir: Vec3,

pub fn at(self: Ray, t: f32) Vec3 {
    return self.origin.add(self.dir.mul(.splat(t)));
}
