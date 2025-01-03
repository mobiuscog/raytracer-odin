package raytracer

import "core:math"
import "core:math/linalg"
import "core:math/rand"

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

random_vector_in_unit_sphere :: proc() -> Vec3 {
    p: Vec3
    for {
        p = 2.0 * {rand.float32(), rand.float32(), rand.float32()} - {1, 1, 1}
        if squared_length(p) < 1.0 {
            break
        }
    }
    return p
}

sqrt_vector :: proc "contextless" (v: ^Vec3) {
    v.x = math.sqrt(v.x)
    v.y = math.sqrt(v.y)
    v.z = math.sqrt(v.z)
}