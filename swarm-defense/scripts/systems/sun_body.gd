extends Node3D

@export var solar_radius: float = 25.0

func get_sun_position() -> Vector3:
    return global_position

func get_power_at_distance(distance: float) -> float:
    if distance <= 0:
        return 0.0
    var max_range = 5000.0
    var t = 1.0 - clamp(distance / max_range, 0.0, 1.0)
    return t * t
