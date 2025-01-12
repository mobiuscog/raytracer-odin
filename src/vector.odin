package raytracer

import "core:math"
import "core:math/linalg"
import "core:math/rand"

Vec3 :: [3]f64

Point3 :: Vec3

vector_dot :: proc(v1: Vec3, v2: Vec3) -> f64 {
    return linalg.vector_dot(v1, v2)
}

vector_cross :: proc(v1: Vec3, v2: Vec3) -> Vec3 {
    return linalg.vector_cross(v1, v2)
}

vector_length :: proc(v: Vec3) -> f64 {
    return linalg.vector_length(v)
}

vector_squared_length :: proc(v: Vec3) -> f64 {
    return linalg.vector_length2(v)
}

vector_unit :: proc(v: Vec3) -> Vec3 {
    return linalg.normalize(v)
}

vector_random :: proc() -> Vec3 {
    return Vec3{rand.float64(), rand.float64(), rand.float64()}
}

vector_random_range :: proc(min: f64, max: f64) -> Vec3 {
    return Vec3{rand.float64_range(min, max), rand.float64_range(min, max), rand.float64_range(min, max)}
}

vector_random_unit :: proc() -> Vec3 {
    p: Vec3
    for {
        p = vector_random_range(-1, 1)
        lensq := vector_squared_length(p)
        if math.F64_EPSILON < lensq && lensq <= 1 {
            return p / math.sqrt(lensq)
        }
    }
}

vector_random_on_hemisphere :: proc(normal: Vec3) -> Vec3 {
    on_unit_sphere := vector_random_unit()
    if vector_dot(on_unit_sphere, normal) > 0 {
        return on_unit_sphere
    }
    return -on_unit_sphere
}

vector_random_in_unit_disk :: proc() -> Vec3 {
    for {
        p := Vec3{rand.float64_range(-1, 1), rand.float64_range(-1, 1), 0}
        if vector_squared_length(p) < 1 {
            return p
        }
    }
}

vector_sqrt :: proc "contextless" (v: ^Vec3) {
    v.x = math.sqrt(v.x)
    v.y = math.sqrt(v.y)
    v.z = math.sqrt(v.z)
}

vector_near_zero :: proc(v: Vec3) -> bool {
    s := 1e-8
    return (math.abs(v.x) < s) && (math.abs(v.y) < s) && (math.abs(v.z) < s)
}