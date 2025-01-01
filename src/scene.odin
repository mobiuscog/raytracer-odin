package raytracer

import "core:math"

Hit_Record :: struct {
    t: f32,
    p: Vec3,
    normal: Vec3,
    material: ^Material,
}

Hittable :: union {
    Sphere,
}

Sphere :: struct {
    center: Vec3,
    radius: f32,
    material: ^Material
}

hit :: proc {
    hit_scene,
    hit_sphere,
}

hit_scene :: proc(scene_objects: []Hittable, r: Ray, t_min: f32, t_max: f32, rec: ^Hit_Record) -> bool {
    temp_rec: Hit_Record
    hit_anything := false
    closest_so_far := t_max
    for object in scene_objects {
            switch t in object {
                case Sphere: // Add additional 'Hittable' types here
                   if hit(t, r, t_min, closest_so_far, &temp_rec) {
                       hit_anything = true
                       closest_so_far = temp_rec.t
                       rec^ = temp_rec
                       rec.material = t.material
                   }
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