const std = @import("std");
const Allocator = std.mem.Allocator;

const HitRecord = @import("hittable.zig").HitRecord;
const Hittable = @import("hittable.zig").Hittable;
const Interval = @import("Interval.zig");
const Ray = @import("Ray.zig");
const Vec3 = @import("Vec3.zig");

const HittableList = @This();

objects: std.ArrayList(Hittable),

pub fn init() HittableList {
    return .{
        .objects = .empty,
    };
}

pub fn deinit(self: *HittableList, gpa: Allocator) void {
    self.objects.deinit(gpa);
}

pub fn add(self: *HittableList, gpa: Allocator, object: Hittable) !void {
    try self.objects.append(gpa, object);
}

pub fn hittable(self: *HittableList) Hittable {
    return .{
        .ptr = self,
        .hitOpaque = hitOpaque,
    };
}

fn hitOpaque(ptr: *anyopaque, r: Ray, ray_t: Interval) ?HitRecord {
    const self: *HittableList = @ptrCast(@alignCast(ptr));

    var current: ?HitRecord = null;
    var closest_so_far = ray_t.max;
    for (self.objects.items) |object| {
        const rec = object.hit(r, .{ .min = ray_t.min, .max = closest_so_far }) orelse continue;
        closest_so_far = rec.t;
        current = rec;
    }
    return current;
}
