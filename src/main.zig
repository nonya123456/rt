const std = @import("std");

const Ray = @import("Ray.zig");

pub fn main(init: std.process.Init) !void {
    const aspect_ratio = 16.0 / 9.0;
    const image_width: i32 = 400;
    const image_height: i32 = @intFromFloat(@as(f64, @floatFromInt(image_width)) / aspect_ratio);

    const focal_length = 1.0;
    const viewport_height = 2.0;
    const viewport_width = viewport_height *
        @as(f64, @floatFromInt(image_width)) / @as(f64, @floatFromInt(image_height));
    const camera_center: Vec3 = .{ 0, 0, 0 };

    const viewport_u: Vec3 = .{ viewport_width, 0, 0 };
    const viewport_v: Vec3 = .{ 0, -viewport_height, 0 };

    const pixel_delta_u = viewport_u / splat3(@floatFromInt(image_width));
    const pixel_delta_v = viewport_v / splat3(@floatFromInt(image_height));

    const viewport_upper_left = camera_center - Vec3{ 0, 0, focal_length } -
        viewport_u / splat3(2.0) - viewport_v / splat3(2.0);
    const pixel00_loc = viewport_upper_left + splat3(0.5) * (pixel_delta_u + pixel_delta_v);

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
            const pixel_center = pixel00_loc + (splat3(@floatFromInt(i)) * pixel_delta_u) +
                (splat3(@floatFromInt(j)) * pixel_delta_v);
            const ray_direction = pixel_center - camera_center;
            const r: Ray = .{ .origin = camera_center, .dir = ray_direction };
            const color = rayColor(r);
            try writeColor(init.gpa, writer, color);
        }
    }

    try writer.flush();
    std.debug.print("Done\n", .{});
}

const Vec3 = @Vector(3, f64);

fn rayColor(r: Ray) Vec3 {
    const unit_direction = unitVector(r.dir);
    const a = 0.5 * (unit_direction[1] + 1.0);
    return splat3(1.0 - a) + splat3(a) * Vec3{ 0.5, 0.7, 1.0 };
}

fn splat3(scalar: f64) Vec3 {
    return @as(Vec3, @splat(scalar));
}

fn unitVector(v: Vec3) Vec3 {
    var v_sq = v * v;
    var s: f64 = 0;
    s += v_sq[0];
    s += v_sq[1];
    s += v_sq[2];
    return v / splat3(@sqrt(s));
}

fn writeColor(gpa: std.mem.Allocator, writer: *std.Io.Writer, color: Vec3) !void {
    const ir: i32 = @intFromFloat(255.999 * color[0]);
    const ig: i32 = @intFromFloat(255.999 * color[1]);
    const ib: i32 = @intFromFloat(255.999 * color[2]);

    const line = try std.fmt.allocPrint(gpa, "{} {} {}\n", .{ ir, ig, ib });
    defer gpa.free(line);

    try writer.writeAll(line);
}
