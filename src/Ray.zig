const Ray = @This();

origin: @Vector(3, f64),
dir: @Vector(3, f64),

fn at(self: Ray, t: f64) @Vector(3, f64) {
    return self.origin + t * self.dir;
}
