const Vec3 = @This();

data: @Vector(3, f32),

pub fn init(data: @Vector(3, f32)) Vec3 {
    return .{ .data = data };
}

pub fn splat(scalar: f32) Vec3 {
    return .{ .data = @as(@Vector(3, f32), @splat(scalar)) };
}

pub fn splatInt(scalar: anytype) Vec3 {
    return .{ .data = @as(@Vector(3, f32), @splat(@floatFromInt(scalar))) };
}

pub fn add(self: Vec3, v: Vec3) Vec3 {
    return .{ .data = self.data + v.data };
}

pub fn sub(self: Vec3, v: Vec3) Vec3 {
    return .{ .data = self.data - v.data };
}

pub fn mul(self: Vec3, v: Vec3) Vec3 {
    return .{ .data = self.data * v.data };
}

pub fn div(self: Vec3, v: Vec3) Vec3 {
    return .{ .data = self.data / v.data };
}

pub fn dot(self: Vec3, v: Vec3) f32 {
    const m = self.data * v.data;
    return m[0] + m[1] + m[2];
}

pub fn length_squared(self: Vec3) f32 {
    return self.dot(self);
}

pub fn length(self: Vec3) f32 {
    return @sqrt(self.length_squared());
}

pub fn normalized(self: Vec3) Vec3 {
    const m: Vec3 = .splat(self.length());
    return .{ .data = self.data / m.data };
}
