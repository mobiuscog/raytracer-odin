package raytracer

Camera :: struct {
    origin: Vec3,
    lower_left_corner: Vec3,
    horizontal: Vec3,
    vertical: Vec3,
}

default_camera :: proc() -> Camera {
    return Camera{
        lower_left_corner = {-2.0, -1.0, -1.0},
        horizontal = {4.0, 0.0, 0.0},
        vertical = {0.0, 2.0, 0.0},
        origin = {},
    }
}

get_ray :: proc(camera: Camera, u: f32, v: f32) -> Ray {
    using camera
    return Ray{origin = origin, direction = lower_left_corner + u * horizontal + v * vertical - origin}
}