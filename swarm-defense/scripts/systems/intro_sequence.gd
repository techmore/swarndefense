extends Node

signal intro_finished()

var _overlay = null
var _obj_tracker = null
var _ship = null
var _launchpad = null
var _cam: Camera3D = null

func begin(world: Node3D, ship: Node3D) -> void:
	_ship = ship
	_overlay = preload("res://scenes/ui/intro_overlay.tscn").instantiate()
	world.add_child(_overlay)

	_spawn_launchpad(world)
	_ship.global_position = _launchpad.global_position + Vector3.UP * 6.0

	_set_ship_locked(true)
	_cam = get_viewport().get_camera_3d()

	_run_sequence()

func _run_sequence() -> void:
	# Phase 1: text over the full solar system view
	await _overlay.play_intro()

	# Phase 2: zoom toward Earth while swarm approaches
	_zoom_to_earth(2.5)
	await _wait(1.0)

	_spawn_scripted_swarm()
	await _overlay.play_swarm_engaged()
	await auto_kill_swarm()
	await _overlay.play_swarm_neutralized()

	await _wait(1.0)
	_setup_objectives()
	await _overlay.play_objective("OBJECTIVE: ESTABLISH FORWARD OPERATING BASE")
	await _wait(3.0)

	_set_ship_locked(false)
	await _overlay.play_outro()

	# Lock camera to ship before launch
	_follow_ship()

	_animate_ship_launch()
	await _wait(2.0)
	_cleanup()
	intro_finished.emit()

# ── Camera helpers ───────────────────────────────────────

func _zoom_to_earth(duration: float) -> void:
	if not _cam or not is_instance_valid(_ship):
		return
	if _cam.has_method("smooth_zoom_to"):
		_cam.smooth_zoom_to(80.0, _ship.global_position, duration)
	elif _cam.has_method("follow_target"):
		_cam.follow_target(_ship.global_position)
		_cam.set("zoom_distance", 80.0)

func _follow_ship() -> void:
	if not _cam or not is_instance_valid(_ship):
		return
	if _cam.has_method("smooth_follow_to"):
		_cam.smooth_follow_to(_ship.global_position, 1.0)
	elif _cam.has_method("follow_target"):
		_cam.follow_target(_ship.global_position)

# ── Launchpad ───────────────────────────────────────────

func _spawn_launchpad(world: Node3D) -> void:
	_launchpad = Node3D.new()
	_launchpad.name = "Launchpad"

	var earth_pos = _find_earth_position()
	_launchpad.global_position = earth_pos + Vector3(0, -5, 0)

	var pad_scene = load("res://assets/quaternius/megakit/platforms/Platform_Metal2.gltf") as PackedScene
	if pad_scene:
		var pad = pad_scene.instantiate() as Node3D
		if pad:
			pad.scale = Vector3.ONE * 2.0
			_launchpad.add_child(pad)
	else:
		var pad = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.top_radius = 8.0
		cyl.bottom_radius = 8.0
		cyl.height = 0.5
		pad.mesh = cyl
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.12, 0.14, 0.18)
		mat.metallic = 0.6
		mat.roughness = 0.5
		pad.material_override = mat
		_launchpad.add_child(pad)

	var ring = MeshInstance3D.new()
	var cyl2 = CylinderMesh.new()
	cyl2.top_radius = 4.5
	cyl2.bottom_radius = 4.5
	cyl2.height = 0.1
	ring.mesh = cyl2
	var rmat = StandardMaterial3D.new()
	rmat.albedo_color = Color(0.05, 0.4, 0.8)
	rmat.emission_enabled = true
	rmat.emission = Color(0.05, 0.4, 0.8) * 0.5
	ring.material_override = rmat
	ring.position.y = 0.3
	_launchpad.add_child(ring)

	world.add_child(_launchpad)

func _find_earth_position() -> Vector3:
	var earth = get_tree().current_scene.find_child("Earth", true, false)
	if earth:
		return earth.global_position
	return Vector3(400, 0, 0)

# ── Ship control ────────────────────────────────────────

func _set_ship_locked(locked: bool) -> void:
	if _ship and _ship.has_method("set_intro_locked"):
		_ship.set_intro_locked(locked)

func _animate_ship_launch() -> void:
	if not is_instance_valid(_ship):
		return
	if _ship.has_method("apply_launch_impulse"):
		_ship.apply_launch_impulse()

# ── Scripted swarm ──────────────────────────────────────

func _spawn_scripted_swarm() -> void:
	var player_pos = _ship.global_position if _ship else Vector3.ZERO
	var angles = [0.0, 2.1, -2.1]
	for a in angles:
		var dist = 120.0
		var pos = player_pos + Vector3(cos(a) * dist, (randf() - 0.5) * 20.0, sin(a) * dist)
		var unit = load("res://scripts/systems/swarm_unit.gd").new()
		unit.global_position = pos
		unit.speed = 18.0
		unit.health = 15.0
		unit.add_to_group("intro_swarm")
		get_tree().current_scene.add_child(unit)

func _find_intro_swarm() -> Array:
	return get_tree().get_nodes_in_group("intro_swarm")

func auto_kill_swarm() -> void:
	var units = _find_intro_swarm()
	if units.is_empty():
		return
	for u in units:
		if not is_instance_valid(u):
			continue
		_spawn_explosion(u.global_position)
		u.queue_free()
		await _wait(0.5)

func _spawn_explosion(pos: Vector3) -> void:
	var boom = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.5
	sphere.rings = 4
	sphere.radial_segments = 6
	boom.mesh = sphere
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.6, 0.1)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.6, 0.1) * 3.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	boom.material_override = mat
	boom.global_position = pos
	get_tree().current_scene.add_child(boom)

	var tw = create_tween()
	tw.tween_property(boom, "scale", Vector3(6, 6, 6), 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)

	var flash = OmniLight3D.new()
	flash.light_energy = 8.0
	flash.omni_range = 30.0
	flash.global_position = pos
	get_tree().current_scene.add_child(flash)
	var tw3 = create_tween()
	tw3.tween_property(flash, "light_energy", 0.0, 0.4)

	await _wait(0.8)
	if is_instance_valid(boom):
		boom.queue_free()
	if is_instance_valid(flash):
		flash.queue_free()

# ── Objectives ──────────────────────────────────────────

func _setup_objectives() -> void:
	_obj_tracker = preload("res://scenes/ui/objective_tracker.tscn").instantiate()
	get_tree().current_scene.add_child(_obj_tracker)

	var objs = [
		{key = "build_solar", text = "Build a Solar Panel", needed = 1, current = 0},
		{key = "build_turret", text = "Build a Turret", needed = 1, current = 0},
		{key = "deposit_metal", text = "Deposit Resources at Base", needed = 50, current = 0},
	]
	_obj_tracker.set_objectives(objs)

	var bm = get_tree().current_scene.find_child("Buildings", true, false)
	if bm and bm.has_signal("building_built"):
		bm.building_built.connect(_on_building_built)
	EconomyManager.resource_deposited.connect(_on_resource_deposited)

func _on_building_built(building_type: String) -> void:
	if building_type == "Solar Panel":
		if _obj_tracker:
			_obj_tracker.update_objective("build_solar", 1)
	elif building_type == "Turret":
		if _obj_tracker:
			_obj_tracker.update_objective("build_turret", 1)

func _on_resource_deposited(rtype: String, amount: int) -> void:
	if rtype == "metal" and _obj_tracker:
		_obj_tracker.update_objective("deposit_metal", amount)

# ── Cleanup ──────────────────────────────────────────────

func _cleanup() -> void:
	if _overlay and is_instance_valid(_overlay):
		_overlay.queue_free()
	if is_instance_valid(_launchpad):
		_launchpad.queue_free()

func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout
