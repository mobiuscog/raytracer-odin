package raytracer

import "core:math/linalg"

Vec3 :: [3]f32

dot :: proc(v1: Vec3, v2: Vec3) -> f32 {
    return linalg.vector_dot(v1, v2)
}

cross :: proc(v1: Vec3, v2: Vec3) -> Vec3 {
    return linalg.vector_cross(v1, v2)
}

length :: proc(v: Vec3) -> f32 {
    return linalg.vector_length(v)
}

squared_length :: proc(v: Vec3) -> f32 {
    return linalg.vector_length2(v)
}

unit_vector :: proc(v: Vec3) -> Vec3 {
    return linalg.normalize(v)
}