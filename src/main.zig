const std = @import("std");

pub fn main(init: std.process.Init) !void {
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
            const b: f64 = 0.0;

            const ir: i32 = @intFromFloat(255.999 * r);
            const ig: i32 = @intFromFloat(255.999 * g);
            const ib: i32 = @intFromFloat(255.999 * b);

            const line = try std.fmt.allocPrint(init.gpa, "{} {} {}\n", .{ ir, ig, ib });
            defer init.gpa.free(line);

            try writer.writeAll(line);
        }
    }

    try writer.flush();
    std.debug.print("Done\n", .{});
}
