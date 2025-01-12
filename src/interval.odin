package raytracer

import "core:math"

Interval :: struct {
    min: f64,
    max: f64,
}

INTERVAL_EMPTY :: Interval{ min = math.INF_F64, max = math.NEG_INF_F64}
INTERVAL_UNIVERSE :: Interval{ min = math.NEG_INF_F64, max = math.INF_F64}


interval :: proc() -> Interval {
    return INTERVAL_EMPTY
}

interval_size :: proc(interval: Interval) -> f64 {
    return interval.max - interval.min
}

interval_contains :: proc(interval: Interval, x: f64) -> bool {
    return interval.min <= x && x <= interval.max
}

interval_surrounds :: proc(interval: Interval, x: f64) -> bool {
    return interval.min < x && x < interval.max
}

interval_clamp :: proc(interval: Interval, x: f64) -> f64 {
    if x < interval.min do return interval.min
    if x > interval.max do return interval.max
    return x
}