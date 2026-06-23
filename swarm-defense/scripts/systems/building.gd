class_name Building
extends Node3D

@export var building_name: String = "Building"
@export var resource_costs: Dictionary = {"metal": 50}
@export var power_consumption: float = 0.0
@export var power_generation: float = 0.0
@export var max_health: float = 100.0
@export var snap_offset: float = 3.0

var health: float
var is_placed: bool = false

signal building_destroyed(building: Building)

func _ready() -> void:
	health = max_health
	add_to_group("buildings")

func take_damage(amount: float, attacker: Node = null) -> void:
	health -= amount
	if health <= 0:
		destroy()

func destroy() -> void:
	building_destroyed.emit(self)
	queue_free()

func get_health_percent() -> float:
	return clamp(health / max_health, 0.0, 1.0)

func get_snap_position(global_hit: Vector3) -> Vector3:
	return global_position

func get_snap_rotation() -> float:
	var buildings = get_tree().get_nodes_in_group("buildings")
	var nearest: Node3D = null
	var nearest_dist = snap_offset * 2.0

	for b in buildings:
		if b == self:
			continue
		var d = global_position.distance_to(b.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = b

	if nearest:
		var dir = global_position - nearest.global_position
		return atan2(dir.x, dir.z)

	return rotation.y
