const Hittable = @import("Hittable.zig");
const HitRecord = Hittable.HitRecord;
const Interval = @import("Interval.zig");
const Ray = @import("Ray.zig");
const Vec3 = @import("Vec3.zig");
const Material = @import("Material.zig");

const Sphere = @This();

center: Vec3,
radius: f32,

pub fn hittable(self: *Sphere) Hittable {
    return .{
        .ptr = self,
        .hitOpaque = hitOpaque,
    };
}

fn hitOpaque(ptr: *anyopaque, r: Ray, ray_t: Interval) ?HitRecord {
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
    if (!ray_t.surrounds(root)) {
        root = (h + sqrtd) / a;
        if (!ray_t.surrounds(root)) {
            return null;
        }
    }

    const t = root;
    const p = r.at(t);
    const outward_normal = p.sub(self.center).div(.splat(self.radius));
    const front_face = r.dir.dot(outward_normal) < 0;
    const normal = if (front_face) outward_normal else outward_normal.neg();
    return .{
        .p = p,
        .normal = normal,
        .t = t,
        .front_face = front_face,
    };
}
