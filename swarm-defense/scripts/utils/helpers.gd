extends Node

static func format_time(seconds: float) -> String:
    var total_ms = int(seconds * 1000)
    var mins = total_ms / 60000
    var secs = (total_ms % 60000) / 1000
    var ms = total_ms % 1000
    return "%02d:%02d.%03d" % [mins, secs, ms]

static func lerp_angle_shortest(from: float, to: float, weight: float) -> float:
    var diff = fmod(to - from + PI, TAU) - PI
    return from + diff * weight

static func random_vector3_in_sphere(radius: float) -> Vector3:
    var theta = randf() * TAU
    var phi = acos(2.0 * randf() - 1.0)
    var r = radius * pow(randf(), 1.0 / 3.0)
    return Vector3(
        r * sin(phi) * cos(theta),
        r * sin(phi) * sin(theta),
        r * cos(phi)
    )

static func vector3_to_string(v: Vector3, decimals: int = 1) -> String:
    return "(%s, %s, %s)" % [v.x.snapped(10.0 ** -decimals), v.y.snapped(10.0 ** -decimals), v.z.snapped(10.0 ** -decimals)]
