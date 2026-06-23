extends Node

var _buildings: Array = []

signal building_placed(building: Node)
signal building_destroyed(building: Node)
signal power_changed(generation: float, consumption: float, stored: float, storage_max: float)
signal building_built(building_type: String)

var _ghost = null
var _build_mode: bool = false
var _pending_scene: PackedScene = null

var total_generation: float = 0.0
var total_consumption: float = 0.0
var battery_stored: float = 0.0
var battery_capacity: float = 0.0
var power_surplus: float = 0.0

func _ready() -> void:
	set_process(true)

func _process(delta: float) -> void:
	_recalculate_power(delta)

func place_building(scene: PackedScene, position: Vector3, rotation_y: float):
	var building = scene.instantiate()
	if not building:
		return null

	for rtype in building.resource_costs:
		if EconomyManager.get_amount(rtype) < building.resource_costs[rtype]:
			return null
		EconomyManager.spend_resource(rtype, building.resource_costs[rtype])

	add_child(building)
	building.global_position = position
	building.rotation.y = rotation_y
	building.is_placed = true
	_buildings.append(building)
	building_placed.emit(building)
	building_built.emit(building.building_name)
	return building

func remove_building(building) -> void:
	if building in _buildings:
		_buildings.erase(building)
		building_destroyed.emit(building)
		building.queue_free()

func _recalculate_power(delta: float) -> void:
	var gen = 0.0
	var con = 0.0
	var bat_stored = 0.0
	var bat_cap = 0.0

	for b in _buildings:
		if not b.is_placed or b.is_queued_for_deletion():
			continue
		if b.power_generation > 0:
			gen += b.power_generation
		if b.power_consumption > 0:
			con += b.power_consumption
		if b.has_method("store_power"):
			bat_stored += b.stored_power
			bat_cap += b.power_storage

	var net = gen - con

	if net > 0 and bat_cap > 0:
		for b in _buildings:
			if b.has_method("store_power") and not b.is_queued_for_deletion():
				net = b.store_power(net)
				if net <= 0:
					break

	if net < 0 and bat_stored > 0:
		for b in _buildings:
			if b.has_method("store_power") and not b.is_queued_for_deletion() and b.stored_power > 0:
				var drawn = b.draw_power(-net)
				net += drawn
				if net >= 0:
					break

	total_generation = gen
	total_consumption = con
	battery_stored = bat_stored
	battery_capacity = bat_cap
	power_surplus = net

func has_power_for(building_type: String) -> bool:
	if building_type == "SolarPanel" or building_type == "Battery":
		return true
	if total_generation >= total_consumption:
		return true
	if battery_stored > 0:
		return true
	return false

func get_power_status() -> Dictionary:
	return {
		"generation": total_generation,
		"consumption": total_consumption,
		"stored": battery_stored,
		"capacity": battery_capacity,
		"surplus": power_surplus,
	}

func enter_build_mode(scene: PackedScene) -> void:
	if _build_mode:
		return
	_build_mode = true
	_pending_scene = scene

	if _ghost:
		_ghost.queue_free()

	var instance = scene.instantiate()
	if not instance:
		_build_mode = false
		return

	_ghost = instance
	add_child(_ghost)
	for child in _ghost.find_children("*", "CollisionShape3D"):
		child.queue_free()
	make_ghost_materials(_ghost)
	_ghost.visible = false

func exit_build_mode(confirm: bool = false) -> void:
	_build_mode = false
	_pending_scene = null
	if _ghost:
		_ghost.queue_free()
		_ghost = null

func update_ghost(from_position: Vector3, from_direction: Vector3) -> void:
	if not _build_mode or not _ghost:
		return

	var place_pos = from_position + from_direction * 60.0
	var snap_pos = _find_snap_position(place_pos)
	var snap_rot = _find_snap_rotation(snap_pos)

	_ghost.global_position = snap_pos
	_ghost.rotation.y = snap_rot
	_ghost.visible = true

	var valid = _validate_placement(_ghost)
	_set_ghost_color(valid)

func confirm_placement() -> void:
	if not _build_mode or not _ghost or not _pending_scene:
		return

	if not _validate_placement(_ghost):
		return

	place_building(_pending_scene, _ghost.global_position, _ghost.rotation.y)
	exit_build_mode()

func _validate_placement(building) -> bool:
	for rtype in building.resource_costs:
		if EconomyManager.get_amount(rtype) < building.resource_costs[rtype]:
			return false

	for b in _buildings:
		if not b.is_queued_for_deletion() and b.global_position.distance_to(building.global_position) < 2.0:
			return false

	return true

func _find_snap_position(pos: Vector3) -> Vector3:
	var nearest = null
	var nearest_dist = 6.0

	for b in _buildings:
		if not b.is_placed:
			continue
		var d = b.global_position.distance_to(pos)
		if d < nearest_dist:
			nearest_dist = d
			nearest = b

	if nearest:
		var dir = (pos - nearest.global_position).normalized()
		return nearest.global_position + dir * nearest.snap_offset
	return pos

func _find_snap_rotation(pos: Vector3) -> float:
	var nearest = null
	var nearest_dist = 8.0

	for b in _buildings:
		if not b.is_placed:
			continue
		var d = b.global_position.distance_to(pos)
		if d < nearest_dist:
			nearest_dist = d
			nearest = b

	if nearest:
		var dir = pos - nearest.global_position
		return atan2(dir.x, dir.z)
	return 0.0

func make_ghost_materials(building) -> void:
	for child in building.find_children("*", "MeshInstance3D"):
		var mi = child as MeshInstance3D
		if mi and mi.mesh:
			var mat = mi.mesh.surface_get_material(0)
			if mat:
				var ghost_mat = mat.duplicate()
				ghost_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				ghost_mat.albedo_color.a = 0.4
				ghost_mat.distance_fade_enabled = false
				mi.material_override = ghost_mat

func _set_ghost_color(valid: bool) -> void:
	if not _ghost:
		return
	var color = Color(0.0, 1.0, 0.0, 0.3) if valid else Color(1.0, 0.0, 0.0, 0.3)
	for child in _ghost.find_children("*", "MeshInstance3D"):
		var mi = child as MeshInstance3D
		if mi and mi.material_override:
			mi.material_override.albedo_color = color

func is_in_build_mode() -> bool:
	return _build_mode

func get_buildings_in_radius(center: Vector3, radius: float) -> Array:
	var result: Array = []
	for b in _buildings:
		if b.is_placed and not b.is_queued_for_deletion():
			if b.global_position.distance_to(center) <= radius:
				result.append(b)
	return result

func get_building_count() -> int:
	return _buildings.size()

func get_buildings() -> Array:
	return _buildings.duplicate()
