package raytracer

import "core:math"

Ray :: struct {
    origin: Vec3,
    direction: Vec3
}

ray_at :: proc(r: Ray, t: f64) -> Vec3 {
    return r.origin + t * r.direction
}

ray_reflect :: proc(v: Vec3, n: Vec3) -> Vec3 {
    return v - 2 * vector_dot(v, n) * n
}

ray_refract :: proc(uv: Vec3, n: Vec3, etai_over_etat: f64) -> Vec3 {
    cos_theta := min(vector_dot(-uv, n), 1)
    r_out_perp := etai_over_etat * (uv + cos_theta * n)
    r_out_parallel := -math.sqrt(f64(abs(1.0 - vector_squared_length(r_out_perp)))) * n
    return r_out_perp + r_out_parallel
}

ray_reflectance :: proc(cosine: f64, ref_idx: f64) -> f64 {
    // Use Schlick'sapproximation
    r0 := (1 - ref_idx) / (1 + ref_idx)
    r0 *= r0
    return r0 + (1 - r0) * math.pow((1 - cosine), 5)
}