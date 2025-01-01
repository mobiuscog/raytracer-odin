package raytracer

import "core:math/rand"

Material :: union {
    Lambertian,
    Metal,
    Dielectric,
}

Lambertian :: struct {
    albedo: Vec3,
}

Metal :: struct {
    albedo: Vec3,
    fuzz: f32,
}

Dielectric :: struct {
    ref_idx: f32
}

scatter :: proc(material: Material, r: Ray, rec: Hit_Record, attenuation: ^Vec3, scattered: ^Ray) -> bool {
    switch &m in material {
    case Lambertian:
        target := rec.p + rec.normal + random_vector_in_unit_sphere()
        scattered^ = Ray{rec.p, target - rec.p}
        attenuation^ = m.albedo
        return true
    case Metal:
        if m.fuzz > 1 do m.fuzz = 1
        reflected := reflect(unit_vector(r.direction), rec.normal)
        scattered^ = Ray{rec.p, reflected + m.fuzz * random_vector_in_unit_sphere()}
        attenuation^ = m.albedo
        return dot(scattered.direction, rec.normal) > 0
    case Dielectric:
        outward_normal: Vec3
        reflected := reflect(r.direction, rec.normal)
        ni_over_nt: f32
        attenuation^ = Vec3{1.0, 1.0, 1.0}
        refracted: Vec3
        reflect_prob: f32
        cosine: f32

        if dot(r.direction, rec.normal) > 0 {
            outward_normal = -rec.normal
            ni_over_nt = m.ref_idx
            cosine = m.ref_idx * dot(r.direction, rec.normal) / length(r.direction)
        }
        else {
            outward_normal = rec.normal
            ni_over_nt = 1.0 / m.ref_idx
            cosine = -dot(r.direction, rec.normal) / length(r.direction)
        }

        if refract(r.direction, outward_normal, ni_over_nt, &refracted) {
            reflect_prob = schlick(cosine, m.ref_idx)
        }
        else {
            reflect_prob = 1.0
        }

        if rand.float32() < reflect_prob {
            scattered^ = Ray{rec.p, reflected}
        }
        else {
            scattered^ = Ray{rec.p, refracted}
        }
        return true
    }
    return false
}