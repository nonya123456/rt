const std = @import("std");

const Camera = @import("Camera.zig");
const HittableList = @import("HittableList.zig");
const Sphere = @import("Sphere.zig");

pub fn main(init: std.process.Init) !void {
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

    var buf: [4096]u8 = undefined;
    var file = try std.Io.Dir.cwd().createFile(init.io, "./img.ppm", .{});
    var file_writer = file.writer(init.io, &buf);
    const writer = &file_writer.interface;

    const aspect_ratio = 16.0 / 9.0;
    const image_width: i32 = 400;
    const camera: Camera = .init(aspect_ratio, image_width, .splat(0));
    try camera.render(writer, world_hittable);
}
