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
    hitOpaque: *const fn (ptr: *anyopaque, r: Ray, ray_tmin: f32, ray_tmax: f32) ?HitRecord,

    pub fn hit(self: Hittable, r: Ray, ray_tmin: f32, ray_tmax: f32) ?HitRecord {
        return self.hitOpaque(self.ptr, r, ray_tmin, ray_tmax);
    }
};
