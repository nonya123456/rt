const Interval = @import("Interval.zig");
const Ray = @import("Ray.zig");
const Vec3 = @import("Vec3.zig");

pub const HitRecord = struct {
    p: Vec3,
    normal: Vec3,
    t: f32,
    front_face: bool,
};

pub const Hittable = struct {
    ptr: *anyopaque,
    hitOpaque: *const fn (ptr: *anyopaque, r: Ray, ray_t: Interval) ?HitRecord,

    pub fn hit(self: Hittable, r: Ray, ray_t: Interval) ?HitRecord {
        return self.hitOpaque(self.ptr, r, ray_t);
    }
};
