package raytracer

import "core:log"
import "core:math/rand"

Camera :: struct {
    image_width: int,
    image_height: int,
    viewport_width: f64,
    viewport_height: f64,
    pixel_delta_u: Vec3,
    pixel_delta_v: Vec3,
    upper_left_location: Point3,
    camera_center: Point3,
    origin: Vec3,
    lower_left_corner: Vec3,
    horizontal: Vec3,
    vertical: Vec3,
    max_depth: int,
}

camera_default :: proc(width: int, aspect_ratio: f64) -> Camera {
    height := int(f64(width) / f64(aspect_ratio))
    log.info("camera init height:", height, "aspect:", aspect_ratio)
    viewport_height: f64 = 2;
    viewport_width: f64 = viewport_height * (f64(width) / f64(height))
    focal_length: f64 = 1;
    camera_center := Point3{}

    // Calculate the vectors along the viewport edges
    viewport_u := Vec3{viewport_width, 0, 0}
    viewport_v := Vec3{0, -viewport_height, 0}

    // Calculate the delta vectors between pixels
    pixel_delta_u := viewport_u / f64(width)
    pixel_delta_v := viewport_v / f64(height)

    // Calculate the location of the top-left pixel
    viewport_upper_left := camera_center - Vec3{0, 0, focal_length} - viewport_u / 2 - viewport_v / 2
    upper_left_location := viewport_upper_left + 0.5 * (pixel_delta_u + pixel_delta_v)

    return Camera{
        image_width = width,
        image_height = height,
        viewport_width = viewport_width,
        viewport_height = viewport_height,
        pixel_delta_u = pixel_delta_u,
        pixel_delta_v = pixel_delta_v,
        upper_left_location = upper_left_location,
        camera_center = camera_center,
        lower_left_corner = {-2.0, -1.0, -1.0},
        horizontal = {4.0, 0.0, 0.0},
        vertical = {0.0, 2.0, 0.0},
        origin = {},
        max_depth = 50,
    }

}

camera_generate_ray :: proc(camera: Camera, x: int, y: int) -> Ray {
    using camera
    offset := sample_square()
    pixel_sample := upper_left_location + ((f64(x) + offset.x) * pixel_delta_u) + ((f64(y) + offset.y) * pixel_delta_v)
    ray_origin := camera_center
    ray_direction := pixel_sample - ray_origin
    return Ray{ray_origin, ray_direction}
}

sample_square :: proc() -> Vec3 {
    return Vec3{rand.float64() - 0.5, rand.float64() - 0.5, 0}
}