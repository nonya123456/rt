const std = @import("std");

const HitRecord = @import("Hittable.zig").HitRecord;
const Material = @import("Material.zig");
const ScatterResult = Material.ScatterResult;
const Ray = @import("Ray.zig");
const Vec3 = @import("Vec3.zig");

const Lambertian = @This();

albedo: Vec3,

pub fn init(albedo: Vec3) Lambertian {
    return .{ .albedo = albedo };
}

pub fn material(self: *Lambertian) Material {
    return .{
        .ptr = self,
        .scatterOpaque = scatterOpaque,
    };
}

fn scatterOpaque(ptr: *anyopaque, rng: std.Random, r_in: Ray, rec: HitRecord) ?ScatterResult {
    _ = r_in;

    const self: *Lambertian = @ptrCast(@alignCast(ptr));

    var dir: Vec3 = rec.normal.add(.randomUnit(rng));
    if (dir.nearZero()) {
        dir = rec.normal;
    }

    const scattered: Ray = .{ .origin = rec.p, .dir = dir };
    const attenuation = self.albedo;
    return .{
        .attenuation = attenuation,
        .scattered = scattered,
    };
}
