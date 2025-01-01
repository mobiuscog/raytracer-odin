package raytracer

Ray :: struct {
    origin: Vec3,
    direction: Vec3
}

point_at_parameter :: proc(r: Ray, t: f32) -> Vec3 {
    return r.origin + t * r.direction
}