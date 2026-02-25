const HitRecord = @import("Hittable.zig").HitRecord;
const Ray = @import("Ray.zig");
const Vec3 = @import("Vec3.zig");

const Material = @This();

pub const ScatterResult = struct {
    attenuation: Vec3,
    scattered: Ray,
};

ptr: *anyopaque,
scatterOpaque: *const fn (ptr: *anyopaque, r_in: Ray, rec: HitRecord) ?ScatterResult,

pub fn scatter(self: Material, r_in: Ray, rec: HitRecord) ?ScatterResult {
    return self.scatterOpaque(self.ptr, r_in, rec);
}
