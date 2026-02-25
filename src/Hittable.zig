const Interval = @import("Interval.zig");
const Material = @import("Material.zig");
const Ray = @import("Ray.zig");
const Vec3 = @import("Vec3.zig");

const Hittable = @This();

pub const HitRecord = struct {
    p: Vec3,
    normal: Vec3,
    t: f32,
    front_face: bool,
    mat: Material,
};

ptr: *anyopaque,
hitOpaque: *const fn (ptr: *anyopaque, r: Ray, ray_t: Interval) ?HitRecord,

pub fn hit(self: Hittable, r: Ray, ray_t: Interval) ?HitRecord {
    return self.hitOpaque(self.ptr, r, ray_t);
}
