const std = @import("std");

const Vec3 = @This();

data: @Vector(3, f32),

pub fn init(data: @Vector(3, f32)) Vec3 {
    return .{ .data = data };
}

pub fn splat(scalar: f32) Vec3 {
    return .{ .data = @as(@Vector(3, f32), @splat(scalar)) };
}

pub fn splatInt(scalar: anytype) Vec3 {
    return .{ .data = @as(@Vector(3, f32), @splat(@floatFromInt(scalar))) };
}

pub fn random(rng: std.Random, min: f32, max: f32) Vec3 {
    const range = max - min;
    const x = rng.float(f32) * range + min;
    const y = rng.float(f32) * range + min;
    const z = rng.float(f32) * range + min;
    return .{ .data = .{ x, y, z } };
}

pub fn randomUnit(rng: std.Random) Vec3 {
    while (true) {
        const p: Vec3 = .random(rng, -1, 1);
        const lensq = p.length_squared();
        if (1e-160 < lensq and lensq < 1) {
            return p.div(.splat(@sqrt(lensq)));
        }
    }
}

pub fn randomInUnitDisk(rng: std.Random) Vec3 {
    while (true) {
        const p: Vec3 = .init(.{
            rng.float(f32) * 2.0 - 1.0,
            rng.float(f32) * 2.0 - 1.0,
            0,
        });
        if (p.length_squared() < 1) {
            return p;
        }
    }
}

pub fn randomOnHemisphere(rng: std.Random, normal: Vec3) Vec3 {
    const on_unit_sphere: Vec3 = .randomUnit(rng);
    if (on_unit_sphere.dot(normal) > 0) {
        return on_unit_sphere;
    }
    return on_unit_sphere.neg();
}

pub fn add(self: Vec3, v: Vec3) Vec3 {
    return .{ .data = self.data + v.data };
}

pub fn sub(self: Vec3, v: Vec3) Vec3 {
    return .{ .data = self.data - v.data };
}

pub fn mul(self: Vec3, v: Vec3) Vec3 {
    return .{ .data = self.data * v.data };
}

pub fn div(self: Vec3, v: Vec3) Vec3 {
    return .{ .data = self.data / v.data };
}

pub fn neg(self: Vec3) Vec3 {
    return .{ .data = -self.data };
}

pub fn cross(self: Vec3, v: Vec3) Vec3 {
    return .{ .data = .{
        self.data[1] * v.data[2] - self.data[2] * v.data[1],
        self.data[2] * v.data[0] - self.data[0] * v.data[2],
        self.data[0] * v.data[1] - self.data[1] * v.data[0],
    } };
}

pub fn dot(self: Vec3, v: Vec3) f32 {
    return @reduce(.Add, self.data * v.data);
}

pub fn length_squared(self: Vec3) f32 {
    return self.dot(self);
}

pub fn length(self: Vec3) f32 {
    return @sqrt(self.length_squared());
}

pub fn normalized(self: Vec3) Vec3 {
    const m: Vec3 = .splat(self.length());
    return .{ .data = self.data / m.data };
}

pub fn nearZero(self: Vec3) bool {
    const s = 1e-8;
    return @abs(self.data[0]) < s and @abs(self.data[1]) < s and @abs(self.data[2]) < s;
}

pub fn reflect(self: Vec3, n: Vec3) Vec3 {
    return self.sub(Vec3.splat(2.0).mul(.splat(self.dot(n))).mul(n));
}

pub fn refract(self: Vec3, n: Vec3, etai_over_etat: f32) Vec3 {
    const cos_theta = @min(self.neg().dot(n), 1.0);
    const r_out_perp = self.add(n.mul(.splat(cos_theta))).mul(.splat(etai_over_etat));
    const r_out_parallel = n.mul(.splat(-@sqrt(@abs(1.0 - r_out_perp.length_squared()))));
    return r_out_perp.add(r_out_parallel);
}
