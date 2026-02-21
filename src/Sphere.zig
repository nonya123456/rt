const HitRecord = @import("hittable.zig").HitRecord;
const Hittable = @import("hittable.zig").Hittable;
const Ray = @import("Ray.zig");
const Vec3 = @import("Vec3.zig");

const Sphere = @This();

center: Vec3,
radius: f32,

pub fn hittable(self: *Sphere) Hittable {
    return .{
        .ptr = self,
        .hitOpaque = hitOpaque,
    };
}

fn hitOpaque(ptr: *anyopaque, r: Ray, ray_tmin: f32, ray_tmax: f32) ?HitRecord {
    const self: *Sphere = @ptrCast(@alignCast(ptr));

    const oc = self.center.sub(r.origin);
    const a = r.dir.length_squared();
    const h = r.dir.dot(oc);
    const c = oc.length_squared() - self.radius * self.radius;
    const discriminant = h * h - a * c;
    if (discriminant < 0) {
        return null;
    }

    const sqrtd = @sqrt(discriminant);
    var root = (h - sqrtd) / a;
    if (root <= ray_tmin or ray_tmax <= root) {
        root = (h + sqrtd) / a;
        if (root <= ray_tmin or ray_tmax <= root) {
            return null;
        }
    }

    const t = root;
    const p = r.at(t);
    const normal = p.sub(self.center).div(.splat(self.radius));
    return .{
        .p = p,
        .normal = normal,
        .t = t,
    };
}
