extends Node

@export var max_health: float = 100.0
@export var armor: float = 0.0

var health: float

signal damaged(amount: float, attacker: Node)
signal destroyed(attacker: Node)
signal health_changed(new_health: float)

func _ready() -> void:
    health = max_health

func take_damage(amount: float, attacker: Node = null) -> void:
    var effective = max(amount - armor, 1.0)
    health -= effective
    health_changed.emit(health)
    damaged.emit(effective, attacker)
    if health <= 0.0:
        destroyed.emit(attacker)

func heal(amount: float) -> void:
    health = min(health + amount, max_health)
    health_changed.emit(health)

func get_health_percent() -> float:
    return health / max_health

func is_alive() -> bool:
    return health > 0.0
