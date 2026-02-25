const std = @import("std");

const Hittable = @import("hittable.zig").Hittable;
const Interval = @import("Interval.zig");
const Ray = @import("Ray.zig");
const Vec3 = @import("Vec3.zig");

const Camera = @This();

rng: std.Random,

image_width: i32,
image_height: i32,
center: Vec3,
pixel00_loc: Vec3,
pixel_delta_u: Vec3,
pixel_delta_v: Vec3,
samples_per_pixel: i32,
max_depth: i32,

pub fn init(
    rng: std.Random,
    aspect_ratio: f32,
    image_width: i32,
    center: Vec3,
    samples_per_pixel: i32,
    max_depth: i32,
) Camera {
    const image_height: i32 = @intFromFloat(@as(f32, @floatFromInt(image_width)) / aspect_ratio);
    const focal_length = 1.0;
    const viewport_height = 2.0;
    const viewport_width = viewport_height * @as(f32, @floatFromInt(image_width)) / @as(f32, @floatFromInt(image_height));

    const viewport_u: Vec3 = .init(.{ viewport_width, 0, 0 });
    const viewport_v: Vec3 = .init(.{ 0, -viewport_height, 0 });

    const pixel_delta_u = viewport_u.div(.splatInt(image_width));
    const pixel_delta_v = viewport_v.div(.splatInt(image_height));

    const viewport_upper_left = center
        .sub(.init(.{ 0, 0, focal_length }))
        .sub(viewport_u.div(.splat(2.0)))
        .sub(viewport_v.div(.splat(2.0)));

    const pixel00_loc = viewport_upper_left.add(Vec3.splat(0.5).mul(pixel_delta_u.add(pixel_delta_v)));

    return .{
        .rng = rng,
        .image_width = image_width,
        .image_height = image_height,
        .center = center,
        .pixel00_loc = pixel00_loc,
        .pixel_delta_u = pixel_delta_u,
        .pixel_delta_v = pixel_delta_v,
        .samples_per_pixel = samples_per_pixel,
        .max_depth = max_depth,
    };
}

pub fn render(self: Camera, writer: *std.Io.Writer, h: Hittable) !void {
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
                const r: Ray = self.getRay(i, j);
                pixel_color = pixel_color.add(rayColor(self.rng, r, h, self.max_depth));
            }
            try writeColor(writer, pixel_color.mul(.splat(pixel_samples_scale)));
        }
    }

    try writer.flush();
    std.debug.print("Done\n", .{});
}

fn getRay(self: Camera, i: i32, j: i32) Ray {
    const i_float: f32 = @floatFromInt(i);
    const j_float: f32 = @floatFromInt(j);
    const offset = self.sampleSquare();
    const pixel_sample = self.pixel00_loc
        .add(self.pixel_delta_u.mul(.splat(i_float + offset.data[0])))
        .add(self.pixel_delta_v.mul(.splat(j_float + offset.data[1])));
    const ray_origin = self.center;
    const ray_direction = pixel_sample.sub(self.center).normalized();
    return .{ .origin = ray_origin, .dir = ray_direction };
}

fn sampleSquare(self: Camera) Vec3 {
    return .init(.{ self.rng.float(f32) - 0.5, self.rng.float(f32) - 0.5, 0 });
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

    const dir: Vec3 = rec.normal.add(.randomUnit(rng));
    const new_ray: Ray = .{ .origin = rec.p, .dir = dir };
    return rayColor(rng, new_ray, h, depth - 1).mul(.splat(0.5));
}

fn writeColor(writer: *std.Io.Writer, color: Vec3) !void {
    const intensity: Interval = .{ .min = 0, .max = 0.999 };
    const ir: i32 = @intFromFloat(256.0 * intensity.clamp(color.data[0]));
    const ig: i32 = @intFromFloat(256.0 * intensity.clamp(color.data[1]));
    const ib: i32 = @intFromFloat(256.0 * intensity.clamp(color.data[2]));
    try writer.print("{} {} {}\n", .{ ir, ig, ib });
}
