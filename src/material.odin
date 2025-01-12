package raytracer

import "core:math"
import "core:math/rand"

Colour :: [3]f64

colour_black :: proc() -> Colour {
    return colour_f64()
}

colour_u8 :: proc(r: u8 = 0, g: u8 = 0, b: u8 = 0) -> Colour {
    return Colour {f64(r) * 0xff, f64(g) * 0xff, f64(b) * 0xff}
}

colour_f64 :: proc(r: f64 = 0, g: f64 = 0, b: f64 = 0) -> Colour {
    return Colour {r, g, b}
}

colour_linear_to_gamma_component :: proc "contextless" (linear_component: f64) -> f64 {
    if linear_component > 0 {
        return math.sqrt(linear_component)
    }
    return 0
}

colour_linear_to_gamma :: proc "contextless" (v: ^Colour) {
    v.r = colour_linear_to_gamma_component(v.r)
    v.g = colour_linear_to_gamma_component(v.g)
    v.b = colour_linear_to_gamma_component(v.b)
}

Material :: union {
    Material_Lambertian,
    Material_Metal,
    Material_Dielectric,
}

Material_Lambertian :: struct {
    albedo: Vec3,
}

Material_Metal :: struct {
    albedo: Vec3,
    fuzz: f64,
}

Material_Dielectric :: struct {
    ref_idx: f64
}

material_scatter :: proc(material: Material, r: Ray, rec: Hit_Record, attenuation: ^Vec3, scattered: ^Ray) -> bool {
    switch &m in material {
    case Material_Lambertian:
        return lambertian_scatter(m, r, rec, attenuation, scattered)
    case Material_Metal:
        return metal_scatter(m, r, rec, attenuation, scattered)
    case Material_Dielectric:
        return dielectric_scatter(m, r, rec, attenuation, scattered)
    }
    return false
}

lambertian_scatter :: proc(m: Material_Lambertian, r: Ray, rec: Hit_Record, attenuation: ^Vec3, scattered: ^Ray) -> bool {
    scatter_direction := rec.normal + vector_random()

    // Catch degenerate scatters
    if vector_near_zero(scatter_direction) {
        scatter_direction = rec.normal
    }
    scattered^ = Ray{rec.p, scatter_direction}
    attenuation^ = m.albedo
    return true
}

metal_scatter :: proc(m: Material_Metal, r: Ray, rec: Hit_Record, attenuation: ^Vec3, scattered: ^Ray) -> bool {
    m := m
    if m.fuzz > 1 do m.fuzz = 1
    reflected := ray_reflect(vector_unit(r.direction), rec.normal)
    scattered^ = Ray{rec.p, reflected + m.fuzz * vector_random_unit()}
    attenuation^ = m.albedo
    return true
}

dielectric_scatter :: proc(m: Material_Dielectric, r: Ray, rec: Hit_Record, attenuation: ^Vec3, scattered: ^Ray) -> bool {
    attenuation^ = Colour{1.0, 1.0, 1.0}
    ri := rec.is_front_face ? (1.0 / m.ref_idx) : m.ref_idx

    unit_direction := vector_unit(r.direction)
    cos_theta := min(vector_dot(-unit_direction, rec.normal), 1)
    sin_theta := math.sqrt(1 - cos_theta * cos_theta)

    cannot_refract := ri * sin_theta > 1
    direction: Vec3

    if cannot_refract || ray_reflectance(cos_theta, ri) > rand.float64() {
        direction = ray_reflect(unit_direction, rec.normal)
    }
    else {
        direction = ray_refract(unit_direction, rec.normal, ri)
    }

    scattered^ = Ray{rec.p, direction}
    return true;
}