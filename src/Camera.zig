const std = @import("std");

const Hittable = @import("hittable.zig").Hittable;
const Ray = @import("Ray.zig");
const Vec3 = @import("Vec3.zig");

const Camera = @This();

image_width: i32,
image_height: i32,
center: Vec3,
pixel00_loc: Vec3,
pixel_delta_u: Vec3,
pixel_delta_v: Vec3,

pub fn init(aspect_ratio: f32, image_width: i32, center: Vec3) Camera {
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
        .image_width = image_width,
        .image_height = image_height,
        .center = center,
        .pixel00_loc = pixel00_loc,
        .pixel_delta_u = pixel_delta_u,
        .pixel_delta_v = pixel_delta_v,
    };
}

pub fn render(self: Camera, writer: *std.Io.Writer, h: Hittable) !void {
    try writer.writeAll("P3\n");
    try writer.print("{} {}\n", .{ self.image_width, self.image_height });
    try writer.writeAll("255\n");

    var j: i32 = 0;
    while (j < self.image_height) : (j += 1) {
        std.debug.print("Scanlines remaining: {}\n", .{self.image_height - j});
        var i: i32 = 0;
        while (i < self.image_width) : (i += 1) {
            const pixel_center = self.pixel00_loc
                .add(self.pixel_delta_u.mul(.splatInt(i)))
                .add(self.pixel_delta_v.mul(.splatInt(j)));
            const ray_direction = pixel_center.sub(self.center).normalized();
            const r: Ray = .{ .origin = self.center, .dir = ray_direction };
            const color = rayColor(r, h);
            try writeColor(writer, color);
        }
    }

    try writer.flush();
    std.debug.print("Done\n", .{});
}

fn rayColor(r: Ray, h: Hittable) Vec3 {
    const rec = h.hit(r, .{ .min = 0, .max = std.math.floatMax(f32) }) orelse {
        const unit_direction = r.dir.normalized();
        const a = 0.5 * (unit_direction.data[1] + 1.0);
        return Vec3.splat(1.0 - a).add(Vec3.splat(a).mul(.init(.{ 0.5, 0.7, 1.0 })));
    };
    return rec.normal.add(.splat(1.0)).mul(.splat(0.5));
}

fn writeColor(writer: *std.Io.Writer, color: Vec3) !void {
    const ir: i32 = @intFromFloat(255.999 * color.data[0]);
    const ig: i32 = @intFromFloat(255.999 * color.data[1]);
    const ib: i32 = @intFromFloat(255.999 * color.data[2]);
    try writer.print("{} {} {}\n", .{ ir, ig, ib });
}
