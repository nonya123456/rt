const std = @import("std");

const HitRecord = @import("Hittable.zig").HitRecord;
const Material = @import("Material.zig");
const ScatterResult = Material.ScatterResult;
const Ray = @import("Ray.zig");
const Vec3 = @import("Vec3.zig");

const Metal = @This();

rng: std.Random,

albedo: Vec3,
fuzz: f32,

pub fn material(self: *Metal) Material {
    return .{
        .ptr = self,
        .scatterOpaque = scatterOpaque,
    };
}

fn scatterOpaque(ptr: *anyopaque, r_in: Ray, rec: HitRecord) ?ScatterResult {
    const self: *Metal = @ptrCast(@alignCast(ptr));
    const fuzz_vec = Vec3.splat(self.fuzz).mul(.randomUnit(self.rng));
    const reflected = r_in.dir.reflect(rec.normal).normalized().add(fuzz_vec);
    const scattered: Ray = .{ .origin = rec.p, .dir = reflected };
    const attenuation = self.albedo;
    return .{
        .attenuation = attenuation,
        .scattered = scattered,
    };
}
