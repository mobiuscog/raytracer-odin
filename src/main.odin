package raytracer

import rl "vendor:raylib"
import "base:intrinsics"
import "core:log"
import "core:math/rand"
import "core:thread"
import "core:math"

WIDTH :: 800
ASPECT_RATIO :: f64(16)/f64(9)
SAMPLES_PER_PIXEL :: 100
NUM_THREADS :: 16

buffer := [dynamic][3]u8{}

Thread_Data :: struct {
    offset: int,
    camera: Camera,
    buffer: ^[dynamic][3]u8,
    complete: bool,
    thread: ^thread.Thread
}

main :: proc() {
    // Seed the RNG
    rand.reset(42)

    // Setup the logging
    logger := log.create_console_logger()
    context.logger = logger
    defer log.destroy_console_logger(logger)

    camera := camera_default(WIDTH, ASPECT_RATIO)
    buffer = make([dynamic][3]u8, camera.image_width * camera.image_height)
    defer delete(buffer)

    // Initialise Window
    rl.SetConfigFlags({.WINDOW_RESIZABLE})
    log.info("Window width:", camera.image_width, "height:", camera.image_height)
    rl.InitWindow(i32(camera.image_width), i32(camera.image_height), "Raytracer")
    defer rl.CloseWindow()
    rl.SetTargetFPS(60)

    // Setup texture to draw on
    image := rl.GenImageColor(i32(camera.image_width), i32(camera.image_height), rl.RED)
    rl.ImageFormat(&image, .UNCOMPRESSED_R8G8B8)
    texture := rl.LoadTextureFromImage(image)
    rl.UnloadImage(image)


    // Start timer
    start_time := rl.GetTime()
    // Launch threads

    // We use an array for the thread data, to avoid allocating per-thread heap memory, but keep threads individual.
    threads := [NUM_THREADS]Maybe(^thread.Thread){}
    thread_data := [NUM_THREADS]Thread_Data{}
    for i in 0..<NUM_THREADS {
        thread_data[i] = Thread_Data{i, camera, &buffer, false, nil}
        // Try to start a thread, returning the value and ok==true if success
        if started, ok := start_thread(&thread_data[i]).?; ok {
            threads[i] = started
        }
        else {
            log.warn("Thread failed to start at index: ", i)
        }
    }

    complete := false

    // Render
    for !rl.WindowShouldClose() {
        rl.BeginDrawing()
        defer rl.EndDrawing()

        rl.ClearBackground(rl.BLACK)
        rl.UpdateTexture(texture, raw_data(buffer)) // We have to use raw_data(...) to get a pointer to the actual data

        // We need to invert the source rect to follow the book.
        rl.DrawTexture(texture, 0, 0, rl.WHITE)

        if !complete {
            unfinished := 0
            for i in 0..<NUM_THREADS {
                if worker, ok := threads[i].?; ok {
                    if (^Thread_Data)(worker.data).complete {
                        thread.join(worker)
                        thread.destroy(worker)
                        threads[i] = nil
                    }
                    else {
                        unfinished += 1
                    }
                }
            }
            if unfinished == 0 {
                complete = true
                end_time := rl.GetTime()
                log.info("All threads completed after:", end_time - start_time, "seconds.")
            }
        }
    }
}

start_thread :: proc(data: ^Thread_Data) -> Maybe(^thread.Thread) {
    if data.thread = thread.create(update); data.thread != nil {
        data.thread.init_context = context
        data.thread.data = rawptr(data)
        thread.start(data.thread)
        return data.thread
    }
    return nil
}

BLUE : Material = Material_Lambertian{albedo = {0.1, 0.2, 0.5}}
GREEN: Material = Material_Lambertian{albedo = {0.8, 0.8, 0.0}}
METAL: Material = Material_Metal{albedo = {0.8, 0.6, 0.2}, fuzz = 0.9}
GLASS: Material = Material_Dielectric{ref_idx = 1.5}
AIR: Material = Material_Dielectric{ref_idx = 1.0 / 1.5}

spheres: []Sphere = {
    Sphere{center = {0, 0, -1}, radius = 0.5, material = &BLUE},
    Sphere{center = {0, -100.5, -1}, radius = 100, material = &GREEN},
    Sphere{center = {1, 0, -1}, radius = 0.5, material = &METAL},
    Sphere{center = {-1, 0, -1}, radius = 0.5, material = &GLASS},
    Sphere{center = {-1, 0, -1}, radius = 0.2, material = &AIR},
}
scene: Scene = {
    spheres,
}

update :: proc(t: ^thread.Thread) {

    data := (^Thread_Data)(t.data)
    camera := data.camera
    for j := data.offset; j < camera.image_height; j += NUM_THREADS {
        for i in 0..<WIDTH {
            pixel_center := camera.upper_left_location + (f64(i) * camera.pixel_delta_u) + (f64(j) * camera.pixel_delta_v)
            ray_direction := pixel_center - camera.center
            ray := Ray{camera.center, ray_direction}
            colour := colour_black()
            for s in 0..<SAMPLES_PER_PIXEL {
                r := camera_generate_ray(camera, i, j)
                colour += ray_colour(r, camera.max_depth, scene)
            }
            colour /= SAMPLES_PER_PIXEL
            colour_linear_to_gamma(&colour)
            col_u8 := to_u8(colour)
            r := f64(i) / (WIDTH - 1)
            g := f64(j) / (f64(data.camera.image_height) - 1)

            data.buffer[j * WIDTH + i] = col_u8
        }
    }
    data.complete = true
}

ray_colour :: proc(ray: Ray, depth: int, scene: Scene) -> Colour {
    if depth <= 0 do return colour_black()
    rec: Hit_Record
    if scene_hit(scene, ray, Interval{0.001, math.INF_F64}, &rec) {
        scattered: Ray
        attenuation: Colour
        if material_scatter(rec.material^, ray, rec, &attenuation, &scattered) {
            return attenuation * ray_colour(scattered, depth - 1, scene)
        }
        return colour_black()
    }
    unit_direction := vector_unit(ray.direction)
    a := 0.5 * (unit_direction.y + 1.0)
    return (1 - a) * colour_f64(1, 1, 1) + a * colour_f64(0.5, 0.7, 1.0)

}

// More to practice generics than being 'good' code
// The returned array is in passed back in the stack frame as it's small enough and known size, so no need to dynamically
// allocate memory
to_u8 :: proc(a: [$N]$E) -> (b: [N]u8) where intrinsics.type_is_float(E) {
    intensity := Interval{0.000, 0.999}
    for i in 0..<N {
        b[i] = u8(256 * interval_clamp(intensity, a[i]))
    }
    return b
}
