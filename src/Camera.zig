const std = @import("std");

const Hittable = @import("Hittable.zig");
const Interval = @import("Interval.zig");
const Ray = @import("Ray.zig");
const Vec3 = @import("Vec3.zig");

const Camera = @This();

image_width: i32,
image_height: i32,
center: Vec3,
pixel00_loc: Vec3,
pixel_delta_u: Vec3,
pixel_delta_v: Vec3,
samples_per_pixel: i32,
max_depth: i32,
vfov: f32,
look_from: Vec3,
look_at: Vec3,
vup: Vec3,
u: Vec3,
v: Vec3,
w: Vec3,
defocus_angle: f32,
focus_dist: f32,
defocus_disk_u: Vec3,
defocus_disk_v: Vec3,

pub fn init(
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
) Camera {
    const image_height: i32 = @intFromFloat(@as(f32, @floatFromInt(image_width)) / aspect_ratio);
    const center = look_from;
    const theta = std.math.degreesToRadians(vfov);
    const h = @tan(theta / 2.0);
    const viewport_height = 2.0 * h * focus_dist;
    const viewport_width = viewport_height * @as(f32, @floatFromInt(image_width)) / @as(f32, @floatFromInt(image_height));

    const w = look_from.sub(look_at).normalized();
    const u = vup.cross(w);
    const v = w.cross(u);

    const viewport_u: Vec3 = u.mul(.splat(viewport_width));
    const viewport_v: Vec3 = v.neg().mul(.splat(viewport_height));

    const pixel_delta_u = viewport_u.div(.splatInt(image_width));
    const pixel_delta_v = viewport_v.div(.splatInt(image_height));

    const viewport_upper_left = center
        .sub(w.mul(.splat(focus_dist)))
        .sub(viewport_u.div(.splat(2.0)))
        .sub(viewport_v.div(.splat(2.0)));

    const pixel00_loc = viewport_upper_left.add(Vec3.splat(0.5).mul(pixel_delta_u.add(pixel_delta_v)));

    const defocus_radius = focus_dist * @tan(std.math.degreesToRadians(defocus_angle / 2.0));
    const defocus_disk_u = u.mul(.splat(defocus_radius));
    const defocus_disk_v = v.mul(.splat(defocus_radius));

    return .{
        .image_width = image_width,
        .image_height = image_height,
        .center = center,
        .pixel00_loc = pixel00_loc,
        .pixel_delta_u = pixel_delta_u,
        .pixel_delta_v = pixel_delta_v,
        .samples_per_pixel = samples_per_pixel,
        .max_depth = max_depth,
        .vfov = vfov,
        .look_from = look_from,
        .look_at = look_at,
        .vup = vup,
        .u = u,
        .v = v,
        .w = w,
        .defocus_angle = defocus_angle,
        .focus_dist = focus_dist,
        .defocus_disk_u = defocus_disk_u,
        .defocus_disk_v = defocus_disk_v,
    };
}

pub fn render(self: Camera, rng: std.Random, writer: *std.Io.Writer, h: Hittable) !void {
    const pixel_samples_scale = 1.0 / @as(f32, @floatFromInt(self.samples_per_pixel));

    try writer.writeAll("P3\n");
    try writer.print("{} {}\n", .{ self.image_width, self.image_height });
    try writer.writeAll("255\n");

    var j: i32 = 0;
    while (j < self.image_height) : (j += 1) {
        std.debug.print("Scanlines remaining: {}\n", .{self.image_height - j});
        var i: i32 = 0;
        while (i < self.image_width) : (i += 1) {
            var pixel_color: Vec3 = .splat(0);
            var sample: i32 = 0;
            while (sample < self.samples_per_pixel) : (sample += 1) {
                const r: Ray = self.getRay(rng, i, j);
                pixel_color = pixel_color.add(rayColor(rng, r, h, self.max_depth));
            }
            try writeColor(writer, pixel_color.mul(.splat(pixel_samples_scale)));
        }
    }

    try writer.flush();
    std.debug.print("Done\n", .{});
}

fn getRay(self: Camera, rng: std.Random, i: i32, j: i32) Ray {
    const i_float: f32 = @floatFromInt(i);
    const j_float: f32 = @floatFromInt(j);
    const offset = sampleSquare(rng);
    const pixel_sample = self.pixel00_loc
        .add(self.pixel_delta_u.mul(.splat(i_float + offset.data[0])))
        .add(self.pixel_delta_v.mul(.splat(j_float + offset.data[1])));
    const ray_origin = if (self.defocus_angle <= 0) self.center else self.defocusDiskSample(rng);
    const ray_direction = pixel_sample.sub(ray_origin).normalized();
    return .{ .origin = ray_origin, .dir = ray_direction };
}

fn sampleSquare(rng: std.Random) Vec3 {
    return .init(.{ rng.float(f32) - 0.5, rng.float(f32) - 0.5, 0 });
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

fn defocusDiskSample(self: Camera, rng: std.Random) Vec3 {
    const p: Vec3 = .randomInUnitDisk(rng);
    return self.center
        .add(self.defocus_disk_u.mul(.splat(p.data[0])))
        .add(self.defocus_disk_v.mul(.splat(p.data[1])));
}
