const std = @import("std");

const Hittable = @import("hittable.zig").Hittable;
const HittableList = @import("HittableList.zig");
const Interval = @import("Interval.zig");
const Ray = @import("Ray.zig");
const Sphere = @import("Sphere.zig");
const Vec3 = @import("Vec3.zig");

pub fn main(init: std.process.Init) !void {
    const aspect_ratio = 16.0 / 9.0;
    const image_width: i32 = 400;
    const image_height: i32 = @intFromFloat(@as(f32, @floatFromInt(image_width)) / aspect_ratio);

    var world: HittableList = .init();

    var sphere1: Sphere = .{
        .center = .init(.{ 0, 0, -1 }),
        .radius = 0.5,
    };
    try world.add(init.arena.allocator(), sphere1.hittable());

    var sphere2: Sphere = .{
        .center = .init(.{ 0, -100.5, -1 }),
        .radius = 100,
    };
    try world.add(init.arena.allocator(), sphere2.hittable());

    const world_hittable = world.hittable();

    const focal_length = 1.0;
    const viewport_height = 2.0;
    const viewport_width = viewport_height * @as(f32, @floatFromInt(image_width)) / @as(f32, @floatFromInt(image_height));
    const camera_center: Vec3 = .splat(0);

    const viewport_u: Vec3 = .init(.{ viewport_width, 0, 0 });
    const viewport_v: Vec3 = .init(.{ 0, -viewport_height, 0 });

    const pixel_delta_u = viewport_u.div(.splatInt(image_width));
    const pixel_delta_v = viewport_v.div(.splatInt(image_height));

    const viewport_upper_left = camera_center
        .sub(.init(.{ 0, 0, focal_length }))
        .sub(viewport_u.div(.splat(2.0)))
        .sub(viewport_v.div(.splat(2.0)));

    const pixel00_loc = viewport_upper_left.add(Vec3.splat(0.5).mul(pixel_delta_u.add(pixel_delta_v)));

    var buf: [4096]u8 = undefined;
    var file = try std.Io.Dir.cwd().createFile(init.io, "./img.ppm", .{});
    var file_writer = file.writer(init.io, &buf);
    var writer = &file_writer.interface;

    try writer.writeAll("P3\n");
    const size = try std.fmt.allocPrint(
        init.arena.allocator(),
        "{} {}\n",
        .{ image_width, image_height },
    );
    try writer.writeAll(size);
    try writer.writeAll("255\n");

    var j: usize = 0;
    while (j < image_height) : (j += 1) {
        std.debug.print("Scanlines remaining: {}\n", .{image_height - j});
        var i: usize = 0;
        while (i < image_width) : (i += 1) {
            const pixel_center = pixel00_loc
                .add(pixel_delta_u.mul(.splatInt(i)))
                .add(pixel_delta_v.mul(.splatInt(j)));
            const ray_direction = pixel_center.sub(camera_center);
            const r: Ray = .{ .origin = camera_center, .dir = ray_direction };
            const color = rayColor(r, world_hittable);
            try writeColor(init.gpa, writer, color);
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

fn writeColor(gpa: std.mem.Allocator, writer: *std.Io.Writer, color: Vec3) !void {
    const ir: i32 = @intFromFloat(255.999 * color.data[0]);
    const ig: i32 = @intFromFloat(255.999 * color.data[1]);
    const ib: i32 = @intFromFloat(255.999 * color.data[2]);

    const line = try std.fmt.allocPrint(gpa, "{} {} {}\n", .{ ir, ig, ib });
    defer gpa.free(line);

    try writer.writeAll(line);
}
