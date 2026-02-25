const std = @import("std");

const Camera = @import("Camera.zig");
const Dialectric = @import("Dialectric.zig");
const HittableList = @import("HittableList.zig");
const Lambertian = @import("Lambertian.zig");
const Metal = @import("Metal.zig");
const Sphere = @import("Sphere.zig");
const Vec3 = @import("Vec3.zig");

pub fn main(init: std.process.Init) !void {
    var arena = init.arena.allocator();

    var prng: std.Random.DefaultPrng = .init(0);
    const rng = prng.random();

    var world: HittableList = .init();
    var ground_material = try arena.create(Lambertian);
    ground_material.* = .init(.init(.{ 0.5, 0.5, 0.5 }));
    var ground = try arena.create(Sphere);
    ground.* = .{
        .center = .init(.{ 0, -1000, 0 }),
        .radius = 1000,
        .mat = ground_material.material(),
    };
    try world.add(arena, ground.hittable());

    var a: i32 = -11;
    while (a < 11) : (a += 1) {
        var b: i32 = -11;
        while (b < 11) : (b += 1) {
            const center: Vec3 = .init(.{
                @as(f32, @floatFromInt(a)) + 0.9 * rng.float(f32),
                0.2,
                @as(f32, @floatFromInt(b)) + 0.9 * rng.float(f32),
            });

            if (center.sub(.init(.{ 4, 0.2, 0 })).length() <= 0.9) {
                continue;
            }

            const choose_mat = rng.float(f32);
            if (choose_mat < 0.8) {
                const albedo: Vec3 = .random(rng, 0, 1);
                const sphere_material = try arena.create(Lambertian);
                sphere_material.* = .init(albedo);
                const sphere = try arena.create(Sphere);
                sphere.* = .{ .center = center, .radius = 0.2, .mat = sphere_material.material() };
                try world.add(arena, sphere.hittable());
                continue;
            }

            if (choose_mat < 0.95) {
                const albedo: Vec3 = .random(rng, 0.5, 1);
                const fuzz = rng.float(f32) / 2.0;
                const sphere_material = try arena.create(Metal);
                sphere_material.* = .init(albedo, fuzz);
                const sphere = try arena.create(Sphere);
                sphere.* = .{ .center = center, .radius = 0.2, .mat = sphere_material.material() };
                try world.add(arena, sphere.hittable());
                continue;
            }

            const sphere_material = try arena.create(Dialectric);
            sphere_material.* = .init(1.5);
            const sphere = try arena.create(Sphere);
            sphere.* = .{ .center = center, .radius = 0.2, .mat = sphere_material.material() };
            try world.add(arena, sphere.hittable());
        }
    }

    var material1 = try arena.create(Dialectric);
    material1.* = .init(1.5);
    var sphere1 = try arena.create(Sphere);
    sphere1.* = .{
        .center = .init(.{ 0, 1, 0 }),
        .radius = 1,
        .mat = material1.material(),
    };
    try world.add(init.arena.allocator(), sphere1.hittable());

    var material2 = try arena.create(Lambertian);
    material2.* = .init(.init(.{ 0.4, 0.2, 0.1 }));
    var sphere2 = try arena.create(Sphere);
    sphere2.* = .{
        .center = .init(.{ -4, 1, 0 }),
        .radius = 1,
        .mat = material2.material(),
    };
    try world.add(init.arena.allocator(), sphere2.hittable());

    var material3 = try arena.create(Metal);
    material3.* = .init(.init(.{ 0.7, 0.6, 0.5 }), 0);
    var sphere3 = try arena.create(Sphere);
    sphere3.* = .{
        .center = .init(.{ 4, 1, 0 }),
        .radius = 1,
        .mat = material3.material(),
    };
    try world.add(init.arena.allocator(), sphere3.hittable());

    var buf: [4096]u8 = undefined;
    var file = try std.Io.Dir.cwd().createFile(init.io, "./img.ppm", .{});
    var file_writer = file.writer(init.io, &buf);
    const writer = &file_writer.interface;

    const camera: Camera = .{
        .aspect_ratio = 16.0 / 9.0,
        .image_width = 1200,
        .samples_per_pixel = 500,
        .max_depth = 50,
        .vfov = 20,
        .look_from = .init(.{ 13, 2, 3 }),
        .look_at = .init(.{ 0, 0, 0 }),
        .vup = .init(.{ 0, 1, 0 }),
        .defocus_angle = 0.6,
        .focus_dist = 10,
    };

    try camera.render(rng, writer, world.hittable());
}
