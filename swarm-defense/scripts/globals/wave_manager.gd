extends Node

var wave_number: int = 0
var enemies_alive: int = 0
var wave_active: bool = false

signal wave_started(wave: int)
signal wave_ended(wave: int)
signal all_waves_complete()

export var waves_before_victory: int = 3

func _ready() -> void:
    pass

func start_next_wave() -> void:
    wave_number += 1
    wave_active = true
    wave_started.emit(wave_number)

func on_enemy_spawned() -> void:
    enemies_alive += 1

func on_enemy_killed() -> void:
    enemies_alive -= 1
    if enemies_alive <= 0 and wave_active:
        _end_wave()

func _end_wave() -> void:
    wave_active = false
    wave_ended.emit(wave_number)
    if wave_number >= waves_before_victory:
        all_waves_complete.emit()

func get_wave_config() -> Dictionary:
    return {
        "count": 5 + wave_number * 3,
        "types": ["scout"] if wave_number == 1 else ["scout", "fighter"] if wave_number == 2 else ["scout", "fighter", "tank"],
        "spawn_interval": max(1.0, 3.0 - wave_number * 0.3)
    }
