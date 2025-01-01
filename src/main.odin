package raytracer

import rl "vendor:raylib"
import "core:fmt"
import "core:log"
import "core:math"
import "core:math/rand"
import "core:mem"
import "core:thread"

WIDTH :: 800
HEIGHT :: 400
SAMPLES_PER_PIXEL :: 100
NUM_THREADS :: 8

Colour :: [4]u8

buffer := [WIDTH * HEIGHT]Colour{}

Thread_Data :: struct {
    offset: int,
    camera: Camera,
    buffer: []Colour,
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


    // Initialise Window
    rl.SetConfigFlags({.WINDOW_RESIZABLE})
    rl.InitWindow(WIDTH, HEIGHT, "Raytracer")
    defer rl.CloseWindow()
    rl.SetTargetFPS(60)

    // Setup texture to draw on
    image := rl.GenImageColor(WIDTH, HEIGHT, rl.RED)
    rl.ImageFormat(&image, .UNCOMPRESSED_R8G8B8A8)
    texture := rl.LoadTextureFromImage(image)
    rl.UnloadImage(image)

    camera := default_camera()

    // Start timer
    start_time := rl.GetTime()
    // Launch threads

    // We use an array for the thread data, to avoid allocating per-thread heap memory, but keep threads individual.
    threads := [NUM_THREADS]Maybe(^thread.Thread){}
    thread_data := [NUM_THREADS]Thread_Data{}
    for i in 0..<NUM_THREADS {
        thread_data[i] = Thread_Data{i, camera, buffer[:], false, nil}
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
        rl.UpdateTexture(texture, &buffer)

        // We need to invert the source rect to follow the book.
        rl.DrawTextureRec(texture, {0, 0, WIDTH, -HEIGHT}, {}, rl.WHITE)

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

scene: []Hittable = {Sphere{center = {0, 0, -1}, radius = 0.5}, Sphere{center = {0, -100.5, -1}, radius = 100}}

update :: proc(t: ^thread.Thread) {

    data := (^Thread_Data)(t.data)
    for j := HEIGHT - 1 - data.offset; j >= 0; j -= NUM_THREADS {
        for i in 0..<WIDTH {
            col := Vec3{}
            for s in 0..<SAMPLES_PER_PIXEL {
                u := (f32(i) + rand.float32()) / WIDTH
                v := (f32(j) + rand.float32()) / HEIGHT
                r := get_ray(data.camera, u, v)
                p := point_at_parameter(r, 2.0)
                col += colour(r, scene)
            }
            col /= f32(SAMPLES_PER_PIXEL)

            ir := u8(255.99 * col.r)
            ig := u8(255.99 * col.g)
            ib := u8(255.99 * col.b)

            data.buffer[j * WIDTH + i] = {ir, ig, ib, 255}
        }
    }
    data.complete = true
}

colour :: proc(r: Ray, scene: []Hittable) -> Vec3 {
    rec: Hit_Record
    if hit_scene(scene, r, 0, math.F32_MAX, &rec) {
        return 0.5 * (rec.normal + 1)
    }
    else {
        unit_direction := unit_vector(r.direction)
        t := 0.5 * (unit_direction.y + 1.0)
        return (1.0 - t) * Vec3{1.0, 1.0, 1.0} + t * Vec3{0.5, 0.7, 1.0}
    }
}