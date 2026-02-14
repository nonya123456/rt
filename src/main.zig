const std = @import("std");

const Ray = @import("Ray.zig");

pub fn main(init: std.process.Init) !void {
    _ = Ray{ .origin = .{ 0, 0, 0 }, .dir = .{ 0, 0, 0 } };

    const image_width = 256;
    const image_height = 256;

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
            const r = @as(f64, @floatFromInt(i)) / @as(f64, @floatFromInt(image_width - 1));
            const g = @as(f64, @floatFromInt(j)) / @as(f64, @floatFromInt(image_height - 1));
            try writeColor(init.gpa, writer, .{ r, g, 0.0 });
        }
    }

    try writer.flush();
    std.debug.print("Done\n", .{});
}

fn writeColor(gpa: std.mem.Allocator, writer: *std.Io.Writer, color: @Vector(3, f64)) !void {
    const ir: i32 = @intFromFloat(255.999 * color[0]);
    const ig: i32 = @intFromFloat(255.999 * color[1]);
    const ib: i32 = @intFromFloat(255.999 * color[2]);

    const line = try std.fmt.allocPrint(gpa, "{} {} {}\n", .{ ir, ig, ib });
    defer gpa.free(line);

    try writer.writeAll(line);
}
