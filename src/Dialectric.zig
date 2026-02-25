const std = @import("std");

const HitRecord = @import("Hittable.zig").HitRecord;
const Material = @import("Material.zig");
const ScatterResult = Material.ScatterResult;
const Ray = @import("Ray.zig");
const Vec3 = @import("Vec3.zig");

const Dialectric = @This();

refraction_index: f32,

pub fn init(refraction_index: f32) Dialectric {
    return .{
        .refraction_index = refraction_index,
    };
}

pub fn material(self: *Dialectric) Material {
    return .{
        .ptr = self,
        .scatterOpaque = scatterOpaque,
    };
}

fn scatterOpaque(ptr: *anyopaque, rng: std.Random, r_in: Ray, rec: HitRecord) ?ScatterResult {
    const self: *Dialectric = @ptrCast(@alignCast(ptr));
    const attenuation: Vec3 = .init(.{ 1, 1, 1 });
    const ri = if (rec.front_face) (1.0 / self.refraction_index) else self.refraction_index;
    const unit_direction = r_in.dir.normalized();

    const cos_theta = @min(unit_direction.neg().dot(rec.normal), 1.0);
    const sin_theta = @sqrt(1.0 - cos_theta * cos_theta);
    const cannot_refract = ri * sin_theta > 1.0;
    const random_float = rng.float(f32);
    var direction: Vec3 = undefined;
    if (cannot_refract or reflectance(cos_theta, self.refraction_index) > random_float) {
        direction = unit_direction.reflect(rec.normal);
    } else {
        direction = unit_direction.refract(rec.normal, ri);
    }
    const scattered: Ray = .{ .origin = rec.p, .dir = direction };
    return .{
        .attenuation = attenuation,
        .scattered = scattered,
    };
}

fn reflectance(cosine: f32, refraction_index: f32) f32 {
    var r0 = (1.0 - refraction_index) / (1.0 + refraction_index);
    r0 = r0 * r0;
    return r0 + (1.0 - r0) * std.math.pow(f32, 1.0 - cosine, 5);
}
