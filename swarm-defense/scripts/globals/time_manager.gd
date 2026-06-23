extends Node

var simulation_speed: float = 1.0
var simulation_time: float = 0.0

signal simulation_speed_changed(new_speed: float)

func _process(delta: float) -> void:
    simulation_time += delta * simulation_speed

func set_speed(speed: float) -> void:
    simulation_speed = max(speed, 0.0)
    simulation_speed_changed.emit(simulation_speed)

func pause_simulation() -> void:
    set_speed(0.0)

func reset_time() -> void:
    simulation_time = 0.0
