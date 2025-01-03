package raytracer

import "core:math"
import "core:math/rand"

Colour :: [3]f32

colour :: proc() -> Colour {
    return colour_f32()
}

colour_u8 :: proc(r: u8 = 0, g: u8 = 0, b: u8 = 0) -> Colour {
    return Colour {f32(r) * 0xff, f32(g) * 0xff, f32(b) * 0xff}
}

colour_f32 :: proc(r: f32 = 0, g: f32 = 0, b: f32 = 0) -> Colour {
    return Colour {r, g, b}
}

sqrt_colour :: proc "contextless" (v: ^Colour) {
    v.r = math.sqrt(v.r)
    v.g = math.sqrt(v.g)
    v.b = math.sqrt(v.b)
}

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
        return scatter_lambertian(m, r, rec, attenuation, scattered)
    case Metal:
        return scatter_metal(m, r, rec, attenuation, scattered)
    case Dielectric:
        return scatter_dielectric(m, r, rec, attenuation, scattered)
    }
    return false
}

scatter_lambertian :: proc(m: Lambertian, r: Ray, rec: Hit_Record, attenuation: ^Vec3, scattered: ^Ray) -> bool {
    target := rec.p + rec.normal + random_vector_in_unit_sphere()
    scattered^ = Ray{rec.p, target - rec.p}
    attenuation^ = m.albedo
    return true
}

scatter_metal :: proc(m: Metal, r: Ray, rec: Hit_Record, attenuation: ^Vec3, scattered: ^Ray) -> bool {
    m := m
    if m.fuzz > 1 do m.fuzz = 1
    reflected := reflect(unit_vector(r.direction), rec.normal)
    scattered^ = Ray{rec.p, reflected + m.fuzz * random_vector_in_unit_sphere()}
    attenuation^ = m.albedo
    return dot(scattered.direction, rec.normal) > 0
}

scatter_dielectric :: proc(m: Dielectric, r: Ray, rec: Hit_Record, attenuation: ^Vec3, scattered: ^Ray) -> bool {
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