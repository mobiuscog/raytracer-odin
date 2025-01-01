package raytracer

import "core:math"

Ray :: struct {
    origin: Vec3,
    direction: Vec3
}

point_at_parameter :: proc(r: Ray, t: f32) -> Vec3 {
    return r.origin + t * r.direction
}

reflect :: proc(v: Vec3, n: Vec3) -> Vec3 {
    return v - 2 * dot(v, n) * n
}

refract :: proc(v: Vec3, n: Vec3, ni_over_nt: f32, refracted: ^Vec3) -> bool {
    uv := unit_vector(v)
    dt := dot(uv, n)
    discriminant := 1.0 - ni_over_nt * ni_over_nt * (1 - dt * dt)
    if discriminant > 0 {
        refracted^ = ni_over_nt * (uv - n * dt) - n * math.sqrt(discriminant)
        return true
    }
    return false
}

schlick :: proc(cosine: f32, ref_idx: f32) -> f32 {
    r0 := (1 - ref_idx) / (1 + ref_idx)
    r0 *= r0
    return r0 + (1 - r0) * math.pow((1 - cosine), 5)
}