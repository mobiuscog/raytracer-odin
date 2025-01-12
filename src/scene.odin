package raytracer

import "core:math"

Scene :: struct {
    spheres: []Sphere
}

Hit_Record :: struct {
    t: f64,
    p: Vec3,
    normal: Vec3,
    is_front_face: bool,
    material: ^Material,
}

Sphere :: struct {
    center: Vec3,
    radius: f64,
    material: ^Material
}

set_face_normal :: proc(rec: ^Hit_Record, ray: Ray, outward_normal: Vec3) {
    rec.is_front_face = vector_dot(ray.direction, outward_normal) < 0
    rec.normal = rec.is_front_face ? outward_normal : -outward_normal
}

scene_hit :: proc(scene: Scene, r: Ray, ray_t: Interval, rec: ^Hit_Record) -> bool {
    temp_rec: Hit_Record
    hit_anything := false
    closest_so_far := ray_t.max
    // Process spheres. If more types, they would follow
    // Potentially depth-sorting/culling could occur first
    for sphere in scene.spheres {
           if sphere_hit(sphere, r, Interval{ray_t.min, closest_so_far}, &temp_rec) {
               hit_anything = true
               closest_so_far = temp_rec.t
               rec^ = temp_rec
               rec.material = sphere.material
           }
    }
    return hit_anything
}

sphere_hit :: proc(s: Sphere, r: Ray, ray_t: Interval, rec: ^Hit_Record) -> bool {
    oc := s.center - r.origin
    a := vector_squared_length(r.direction)
    h := vector_dot(r.direction, oc)
    c := vector_squared_length(oc) - s.radius * s.radius
    discriminant := h * h - a * c

    if discriminant < 0 {
        return false
    }

    sqrtd := math.sqrt(discriminant)
    root := (h - sqrtd) / a
    if !interval_surrounds(ray_t, root) {
        root = (h + sqrtd) / a
        if !interval_surrounds(ray_t, root) {
            return false
        }
    }

    rec.t = root
    rec.p = ray_at(r, rec.t)
    outward_normal := (rec.p - s.center) / s.radius
    set_face_normal(rec, r, outward_normal)

    return true
}