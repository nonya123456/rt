const std = @import("std");

const Camera = @import("Camera.zig");
const HittableList = @import("HittableList.zig");
const Lambertian = @import("Lambertian.zig");
const Metal = @import("Metal.zig");
const Sphere = @import("Sphere.zig");

pub fn main(init: std.process.Init) !void {
    var prng: std.Random.DefaultPrng = .init(0);
    const rng = prng.random();

    var material_ground: Lambertian = .{
        .rng = rng,
        .albedo = .init(.{ 0.8, 0.8, 0 }),
    };
    var material_center: Lambertian = .{
        .rng = rng,
        .albedo = .init(.{ 0.1, 0.2, 0.5 }),
    };
    var material_left: Metal = .{
        .rng = rng,
        .albedo = .init(.{ 0.8, 0.8, 0.8 }),
        .fuzz = 0.3,
    };
    var material_right: Metal = .{
        .rng = rng,
        .albedo = .init(.{ 0.8, 0.6, 0.2 }),
        .fuzz = 1,
    };

    var world: HittableList = .init();

    var sphere1: Sphere = .{
        .center = .init(.{ 0, -100.5, -1 }),
        .radius = 100,
        .mat = material_ground.material(),
    };
    try world.add(init.arena.allocator(), sphere1.hittable());

    var sphere2: Sphere = .{
        .center = .init(.{ 0, 0, -1.2 }),
        .radius = 0.5,
        .mat = material_center.material(),
    };
    try world.add(init.arena.allocator(), sphere2.hittable());

    var sphere3: Sphere = .{
        .center = .init(.{ -1, 0, -1 }),
        .radius = 0.5,
        .mat = material_left.material(),
    };
    try world.add(init.arena.allocator(), sphere3.hittable());

    var sphere4: Sphere = .{
        .center = .init(.{ 1, 0, -1 }),
        .radius = 0.5,
        .mat = material_right.material(),
    };
    try world.add(init.arena.allocator(), sphere4.hittable());

    const world_hittable = world.hittable();

    var buf: [4096]u8 = undefined;
    var file = try std.Io.Dir.cwd().createFile(init.io, "./img.ppm", .{});
    var file_writer = file.writer(init.io, &buf);
    const writer = &file_writer.interface;

    const aspect_ratio = 16.0 / 9.0;
    const image_width: i32 = 400;
    const camera: Camera = .init(rng, aspect_ratio, image_width, .splat(0), 100, 50);
    try camera.render(writer, world_hittable);
}
