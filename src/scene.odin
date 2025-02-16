package raytracer

import "core:math"
import "core:math/rand"

Scene :: struct {
    spheres: [dynamic]Sphere,
    materials: [dynamic]Material,
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

scene_build :: proc() -> Scene {
    spheres := make([dynamic]Sphere, 576, context.temp_allocator)
    materials := make([dynamic]Material, 576, context.temp_allocator)

    sphere_material: Material = Material_Lambertian{{0.5, 0.5, 0.5}}
    append(&materials, sphere_material)
    append(&spheres, Sphere{Point3{0, -1000, 0}, 1000, &materials[len(materials)-1]})

    for a in -11..<11 {
        for b in -11..<11 {
            choose_mat := rand.float64()
            center := Point3{f64(a) + 0.9 * rand.float64(), 0.2, f64(b) + 0.9 * rand.float64()}

            if vector_length(center - Point3{4, 0.2, 0}) > 0.9 {
                if choose_mat < 0.9 {
                    albedo := colour_random() * colour_random()
                    sphere_material = Material_Lambertian{albedo}
                }
                else if choose_mat < 0.95 {
                    albedo := colour_random_range(0.5, 1)
                    fuzz := rand.float64_range(0, 0.5)
                    sphere_material = Material_Metal{albedo, fuzz}
                }
                else {
                    sphere_material = Material_Dielectric{1.5}
                }
                append(&materials, sphere_material)
                sphere := Sphere{center, 0.2, &materials[len(materials)-1]}
                append(&spheres, sphere)
            }
        }
    }
    sphere_material = Material_Dielectric{1.5}
    append(&materials, sphere_material)
    append(&spheres, Sphere{Point3{0, 1, 0}, 1, &materials[len(materials)-1]})
    sphere_material = Material_Lambertian{Colour{0.4, 0.2, 0.1}}
    append(&materials, sphere_material)
    append(&spheres, Sphere{Point3{-4, 1, 0}, 1, &materials[len(materials)-1]})
    sphere_material = Material_Metal{Colour{0.7, 0.6, 0.5}, 0.0}
    append(&materials, sphere_material)
    append(&spheres, Sphere{Point3{4, 1, 0}, 1, &materials[len(materials)-1]})
    return Scene{spheres, materials}
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