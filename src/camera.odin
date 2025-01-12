package raytracer

import "core:log"
import "core:math/rand"
import "core:math"

Camera :: struct {
    image_width: int,
    image_height: int,
    viewport_width: f64,
    viewport_height: f64,
    pixel_delta_u: Vec3,
    pixel_delta_v: Vec3,
    upper_left_location: Point3,
    center: Point3,
    origin: Vec3,
    lower_left_corner: Vec3,
    horizontal: Vec3,
    vertical: Vec3,
    max_depth: int,
    defocus_angle: f64,
    defocus_disk_u: Vec3,
    defocus_disk_v: Vec3,
}

camera_default :: proc(width: int, aspect_ratio: f64) -> Camera {
    height := max(int(f64(width) / f64(aspect_ratio)), 1)

    // Determine viewport dimensions
    vfov:f64 = 20
    look_from := Point3{13, 2, 3}
    look_at := Point3{0, 0, 0}
    v_up := Vec3{0, 1, 0}

    defocus_angle := f64(0.6)
    focus_dist := f64(10.0)

    center := look_from

    focal_length: f64 = vector_length(look_from - look_at)

    theta := math.to_radians(vfov)
    h := math.tan(theta / 2)
    viewport_height: f64 = 2 * h * focus_dist
    viewport_width: f64 = viewport_height * (f64(width) / f64(height))

    // Calculate the u,v,w unit basis vectors for the camera coordinate frame
    w := vector_unit(look_from - look_at)
    u := vector_unit(vector_cross(v_up, w))
    v := vector_cross(w, u)

    // Calculate the vectors along the viewport edges
    viewport_u := viewport_width * u
    viewport_v := viewport_height * -v

    // Calculate the delta vectors between pixels
    pixel_delta_u := viewport_u / f64(width)
    pixel_delta_v := viewport_v / f64(height)

    // Calculate the location of the top-left pixel
    viewport_upper_left := center - (focus_dist * w) - viewport_u / 2 - viewport_v / 2
    upper_left_location := viewport_upper_left + 0.5 * (pixel_delta_u + pixel_delta_v)

    // Calculate the camera defocus disk basis vectors
    defocus_radius := focus_dist * math.tan(math.to_radians(defocus_angle / 2))
    defocus_disk_u := u * defocus_radius
    defocus_disk_v := v * defocus_radius

    return Camera{
        image_width = width,
        image_height = height,
        viewport_width = viewport_width,
        viewport_height = viewport_height,
        pixel_delta_u = pixel_delta_u,
        pixel_delta_v = pixel_delta_v,
        upper_left_location = upper_left_location,
        center = center,
        lower_left_corner = {-2.0, -1.0, -1.0},
        horizontal = {4.0, 0.0, 0.0},
        vertical = {0.0, 2.0, 0.0},
        origin = {},
        max_depth = 50,
        defocus_angle = defocus_angle,
        defocus_disk_u = defocus_disk_u,
        defocus_disk_v = defocus_disk_v,
    }

}

camera_generate_ray :: proc(camera: Camera, x: int, y: int) -> Ray {
    // Construct a camera ray originating from the defocus disk and directed at a randomly
    // sampled point around the pixel location x, y
    using camera
    offset := sample_square()
    pixel_sample := upper_left_location + ((f64(x) + offset.x) * pixel_delta_u) + ((f64(y) + offset.y) * pixel_delta_v)
    ray_origin := (camera.defocus_angle <= 0) ? center : camera_defocus_disk_sample(camera)
    ray_direction := pixel_sample - ray_origin
    return Ray{ray_origin, ray_direction}
}

sample_square :: proc() -> Vec3 {
    return Vec3{rand.float64() - 0.5, rand.float64() - 0.5, 0}
}

camera_defocus_disk_sample :: proc(camera: Camera) -> Point3 {
    // Returns a random point in the camera defocus disk
    p := vector_random_in_unit_disk()
    return camera.center + (p.x * camera.defocus_disk_u) + (p.y * camera.defocus_disk_v)
}