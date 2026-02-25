const std = @import("std");

const Hittable = @import("Hittable.zig");
const Interval = @import("Interval.zig");
const Ray = @import("Ray.zig");
const Vec3 = @import("Vec3.zig");

const Camera = @This();

aspect_ratio: f32,
image_width: i32,
samples_per_pixel: i32,
max_depth: i32,
vfov: f32,
look_from: Vec3,
look_at: Vec3,
vup: Vec3,
defocus_angle: f32,
focus_dist: f32,

pub fn render(self: Camera, rng: std.Random, writer: *std.Io.Writer, h: Hittable) !void {
    const image_height: i32 = @intFromFloat(@as(f32, @floatFromInt(self.image_width)) / self.aspect_ratio);

    const theta = std.math.degreesToRadians(self.vfov);
    const hh = @tan(theta / 2.0);
    const viewport_height = 2.0 * hh * self.focus_dist;
    const viewport_width = viewport_height * @as(f32, @floatFromInt(self.image_width)) / @as(f32, @floatFromInt(image_height));

    const w = self.look_from.sub(self.look_at).normalized();
    const u = self.vup.cross(w);
    const v = w.cross(u);

    const viewport_u: Vec3 = u.mul(.splat(viewport_width));
    const viewport_v: Vec3 = v.neg().mul(.splat(viewport_height));

    const pixel_delta_u = viewport_u.div(.splatInt(self.image_width));
    const pixel_delta_v = viewport_v.div(.splatInt(image_height));

    const viewport_upper_left = self.look_from
        .sub(w.mul(.splat(self.focus_dist)))
        .sub(viewport_u.div(.splat(2.0)))
        .sub(viewport_v.div(.splat(2.0)));

    const pixel00_loc = viewport_upper_left.add(Vec3.splat(0.5).mul(pixel_delta_u.add(pixel_delta_v)));

    const defocus_radius = self.focus_dist * @tan(std.math.degreesToRadians(self.defocus_angle / 2.0));
    const defocus_disk_u = u.mul(.splat(defocus_radius));
    const defocus_disk_v = v.mul(.splat(defocus_radius));

    const pixel_samples_scale = 1.0 / @as(f32, @floatFromInt(self.samples_per_pixel));

    try writer.writeAll("P3\n");
    try writer.print("{} {}\n", .{ self.image_width, image_height });
    try writer.writeAll("255\n");

    var j: i32 = 0;
    while (j < image_height) : (j += 1) {
        std.debug.print("Scanlines remaining: {}\n", .{image_height - j});
        var i: i32 = 0;
        while (i < self.image_width) : (i += 1) {
            const i_f: f32 = @floatFromInt(i);
            const j_f: f32 = @floatFromInt(j);
            var pixel_color: Vec3 = .splat(0);
            var sample: i32 = 0;
            while (sample < self.samples_per_pixel) : (sample += 1) {
                const offset = sampleSquare(rng);
                const pixel_sample = pixel00_loc
                    .add(pixel_delta_u.mul(.splat(i_f + offset.data[0])))
                    .add(pixel_delta_v.mul(.splat(j_f + offset.data[1])));
                const ray_origin = if (self.defocus_angle <= 0)
                    self.look_from
                else
                    defocusDiskSample(rng, self.look_from, defocus_disk_u, defocus_disk_v);
                const ray_direction = pixel_sample.sub(ray_origin).normalized();
                const r: Ray = .{ .origin = ray_origin, .dir = ray_direction };
                pixel_color = pixel_color.add(rayColor(rng, r, h, self.max_depth));
            }
            try writeColor(writer, pixel_color.mul(.splat(pixel_samples_scale)));
        }
    }

    try writer.flush();
    std.debug.print("Done\n", .{});
}

fn sampleSquare(rng: std.Random) Vec3 {
    return .init(.{ rng.float(f32) - 0.5, rng.float(f32) - 0.5, 0 });
}

fn defocusDiskSample(rng: std.Random, center: Vec3, disk_u: Vec3, disk_v: Vec3) Vec3 {
    const p: Vec3 = .randomInUnitDisk(rng);
    return center
        .add(disk_u.mul(.splat(p.data[0])))
        .add(disk_v.mul(.splat(p.data[1])));
}

fn rayColor(rng: std.Random, r: Ray, h: Hittable, depth: i32) Vec3 {
    if (depth <= 0) {
        return .splat(0);
    }

    const rec = h.hit(r, .{ .min = 0.001, .max = std.math.floatMax(f32) }) orelse {
        const unit_direction = r.dir.normalized();
        const a = 0.5 * (unit_direction.data[1] + 1.0);
        return Vec3.splat(1.0 - a).add(Vec3.splat(a).mul(.init(.{ 0.5, 0.7, 1.0 })));
    };

    const res = rec.mat.scatter(rng, r, rec) orelse {
        return .splat(0);
    };
    return rayColor(rng, res.scattered, h, depth - 1).mul(res.attenuation);
}

fn writeColor(writer: *std.Io.Writer, color: Vec3) !void {
    const intensity: Interval = .{ .min = 0, .max = 0.999 };

    const r = linearToGamma(color.data[0]);
    const g = linearToGamma(color.data[1]);
    const b = linearToGamma(color.data[2]);

    const ir: i32 = @intFromFloat(256.0 * intensity.clamp(r));
    const ig: i32 = @intFromFloat(256.0 * intensity.clamp(g));
    const ib: i32 = @intFromFloat(256.0 * intensity.clamp(b));
    try writer.print("{} {} {}\n", .{ ir, ig, ib });
}

fn linearToGamma(linear_component: f32) f32 {
    if (linear_component > 0) {
        return @sqrt(linear_component);
    }
    return 0;
}
