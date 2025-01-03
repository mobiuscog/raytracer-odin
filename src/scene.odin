package raytracer

import "core:math"

Scene :: struct {
    spheres: []Sphere
}

Hit_Record :: struct {
    t: f32,
    p: Vec3,
    normal: Vec3,
    material: ^Material,
}

Sphere :: struct {
    center: Vec3,
    radius: f32,
    material: ^Material
}

hit_scene :: proc(scene: Scene, r: Ray, t_min: f32, t_max: f32, rec: ^Hit_Record) -> bool {
    temp_rec: Hit_Record
    hit_anything := false
    closest_so_far := t_max
    // Process spheres. If more types, they would follow
    // Potentially depth-sorting/culling could occur first
    for sphere in scene.spheres {
           if hit_sphere(sphere, r, t_min, closest_so_far, &temp_rec) {
               hit_anything = true
               closest_so_far = temp_rec.t
               rec^ = temp_rec
               rec.material = sphere.material
           }
    }
    return hit_anything
}

hit_sphere :: proc(s: Sphere, r: Ray, t_min: f32, t_max: f32, rec: ^Hit_Record) -> bool {
    oc := r.origin - s.center
    a := dot(r.direction, r.direction)
    b := dot(oc, r.direction)
    c := dot(oc, oc) - s.radius * s.radius
    discriminant := b * b - a * c
    if discriminant > 0 {
        temp := (-b - math.sqrt(b * b - a * c)) / a
        if temp < t_max && temp > t_min {
            rec.t = temp
            rec.p = point_at_parameter(r, rec.t)
            rec.normal = (rec.p - s.center) / s.radius
            return true
        }
        temp = (-b + math.sqrt(b * b - a * c)) / a
        if temp < t_max && temp > t_min {
            rec.t = temp
            rec.p = point_at_parameter(r, rec.t)
            rec.normal = (rec.p - s.center) / s.radius
            return true
        }

    }
    return false
}