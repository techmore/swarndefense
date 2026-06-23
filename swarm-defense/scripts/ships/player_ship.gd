extends CharacterBody3D

@export var thrust_force: float = 60.0
@export var boost_multiplier: float = 3.0
@export var max_speed: float = 150.0
@export var max_boost_speed: float = 350.0
@export var boost_drain: float = 12.0
@export var boost_regen: float = 6.0
@export var linear_drag: float = 0.4
@export var angular_drag: float = 4.0
@export var mining_range: float = 80.0
@export var mining_rate: int = 5
@export var cargo_capacity: int = 500

var _velocity: Vector3 = Vector3.ZERO
var _angular_velocity: Vector3 = Vector3.ZERO
var _boost: float = 100.0
var _is_boosting: bool = false
var _mouse_captured: bool = false
var _throttle: float = 0.0
var _lateral_intensity: float = 0.0
var _cargo: Dictionary = {"metal": 0, "crystal": 0}
var _mining_active: bool = false
var _mining_hit: Vector3 = Vector3.ZERO
var _build_mode: bool = false
var _build_menu: BuildMenu = null
var _building_manager: BuildingManager = null

@onready var camera_pivot: Node3D = $CameraPivot
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var thruster_main: GPUParticles3D = $ThrusterMain
@onready var thruster_left: GPUParticles3D = $ThrusterLeft
@onready var thruster_right: GPUParticles3D = $ThrusterRight
@onready var headlight: OmniLight3D = $Headlight
@onready var engine_accent_l: MeshInstance3D = $EngineAccentLeft
@onready var engine_accent_r: MeshInstance3D = $EngineAccentRight
@onready var mining_ray: RayCast3D = $MiningRay
@onready var mining_beam: MeshInstance3D = $MiningBeam

func _ready() -> void:
	add_to_group("player_ship")
	_setup_thrusters()
	mining_beam.visible = false
	_building_manager = get_tree().current_scene.find_child("Buildings", true, false) as BuildingManager
	_build_menu = get_tree().current_scene.find_child("BuildMenu", true, false) as BuildMenu
	if _build_menu:
		_build_menu.building_selected.connect(_on_building_selected)
		_build_menu.menu_closed.connect(_on_build_menu_closed)

func _setup_thrusters() -> void:
	for t in [thruster_main, thruster_left, thruster_right]:
		if not t:
			continue
		var mat = ParticleProcessMaterial.new()
		mat.gravity = Vector3.ZERO
		mat.initial_velocity_min = 4.0
		mat.initial_velocity_max = 8.0
		mat.direction = Vector3.BACK
		mat.spread = 15.0
		mat.scale_min = 0.1
		mat.scale_max = 0.3
		mat.lifetime_randomness = 0.4
		mat.color = Color(0.3, 0.7, 1.0, 0.6)
		mat.color_ramp = _make_flame_gradient()
		t.process_material = mat
		t.emitting = true

func _make_flame_gradient() -> Gradient:
	var g = Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.3, 0.7, 1.0])
	g.colors = PackedColorArray([
		Color(1.0, 1.0, 1.0, 1.0),
		Color(0.4, 0.8, 1.0, 0.8),
		Color(0.1, 0.3, 0.8, 0.3),
		Color(0.0, 0.0, 0.1, 0.0)
	])
	return g

func _input(event: InputEvent) -> void:
	if _build_menu and _build_menu.menu_active:
		return

	if _build_mode:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_confirm_build()
			return
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_cancel_build()
			return
		if event.is_action_pressed("build_menu"):
			_cancel_build()
			return
		return

	if event.is_action_pressed("build_menu"):
		if _build_menu:
			_build_menu.show_menu()
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not _mouse_captured:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			_mouse_captured = true
	if event.is_action_pressed("pause"):
		if _mouse_captured:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			_mouse_captured = false
	if event.is_action_pressed("interact"):
		_deposit_cargo()

func _on_building_selected(building_type: Dictionary) -> void:
	if not _building_manager:
		return
	var scene = load(building_type["scene"]) as PackedScene
	if not scene:
		return
	if _mouse_captured:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		_mouse_captured = false
	_build_mode = true
	_building_manager.enter_build_mode(scene)

func _on_build_menu_closed() -> void:
	pass

func _confirm_build() -> void:
	if _building_manager and _building_manager.is_in_build_mode():
		_building_manager.confirm_placement()
		_build_mode = false

func _cancel_build() -> void:
	if _building_manager and _building_manager.is_in_build_mode():
		_building_manager.exit_build_mode()
	_build_mode = false

func _physics_process(delta: float) -> void:
	_handle_input(delta)
	_apply_movement(delta)
	_update_mining(delta)
	_update_thrusters(delta)
	_update_camera(delta)

	if _build_mode and _building_manager and _building_manager.is_in_build_mode():
		_update_ghost_preview()

func _handle_input(delta: float) -> void:
	var input = InputHandler.get_movement_vector()
	var boost = Input.is_action_pressed("boost")

	_is_boosting = boost and _boost > 0.0
	_throttle = -input.z
	_lateral_intensity = Vector2(input.x, input.y).length()

	if _build_mode:
		return

	if input.length() > 0.0:
		var world_input = global_transform.basis * input
		var force_mult = (boost_multiplier if _is_boosting else 1.0)
		_velocity += world_input * thrust_force * force_mult * delta

	if _mouse_captured:
		var mouse = Input.get_last_mouse_velocity()
		_angular_velocity.y -= mouse.x * 0.002
		_angular_velocity.x -= mouse.y * 0.002
	_angular_velocity.x = clamp(_angular_velocity.x, -PI, PI)

func _apply_movement(delta: float) -> void:
	var current_max = max_boost_speed if _is_boosting else max_speed
	if _velocity.length() > current_max:
		_velocity = _velocity.normalized() * current_max

	var drag_force = _velocity * linear_drag * delta
	_velocity -= drag_force

	velocity = _velocity
	move_and_slide()

	rotation.y += _angular_velocity.y * delta
	camera_pivot.rotation.x += _angular_velocity.x * delta
	camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, -PI * 0.35, PI * 0.35)

	_angular_velocity *= max(0.0, 1.0 - angular_drag * delta)

	if _is_boosting:
		_boost = max(_boost - boost_drain * delta, 0.0)
	else:
		_boost = min(_boost + boost_regen * delta, 100.0)

func _update_mining(delta: float) -> void:
	if _build_mode:
		mining_beam.visible = false
		_mining_active = false
		return

	var firing = Input.is_action_pressed("primary_fire")

	if not firing or not _mouse_captured:
		mining_beam.visible = false
		_mining_active = false
		return

	mining_ray.target_position = Vector3(0, 0, -mining_range)
	mining_ray.force_raycast_update()

	if not mining_ray.is_colliding():
		mining_beam.visible = false
		_mining_active = false
		return

	var hit = mining_ray.get_collision_point()
	var collider = mining_ray.get_collider()

	if not collider or collider.name != "AsteroidField":
		mining_beam.visible = false
		_mining_active = false
		return

	_mining_active = true
	_mining_hit = hit
	_update_beam_visual(hit)

	var field = collider as AsteroidField
	if field:
		var collected = field.mine_asteroid(hit, mining_rate)
		if collected:
			_add_to_cargo(collected)

func _update_beam_visual(hit: Vector3) -> void:
	var local_hit = global_transform.basis.inverse() * (hit - global_position)
	var mid = local_hit * 0.5
	var dist = local_hit.length()

	mining_beam.position = Vector3(0, 0, -dist * 0.5)
	mining_beam.scale = Vector3(1, 1, dist)
	mining_beam.look_at(local_hit, Vector3.UP)
	mining_beam.visible = true

func _add_to_cargo(collected: Dictionary) -> void:
	var total = 0
	for v in _cargo.values():
		total += v
	for rtype in collected:
		var space = cargo_capacity - total
		if space <= 0:
			break
		var add = mini(collected[rtype], space)
		_cargo[rtype] = _cargo.get(rtype, 0) + add
		total += add

func _deposit_cargo() -> void:
	var deposited = 0
	for rtype in _cargo:
		var amount = _cargo[rtype]
		if amount > 0:
			var added = EconomyManager.add_resource(rtype, amount, "ship_deposit")
			_cargo[rtype] -= added
			deposited += added

func _update_thrusters(delta: float) -> void:
	var main_intensity = clamp(abs(_throttle) + (0.2 if _is_boosting else 0.0), 0.0, 1.0)
	thruster_main.amount = int(50 * main_intensity)
	thruster_main.lifetime = 0.2 + 0.3 * main_intensity

	var mat = thruster_main.process_material as ParticleProcessMaterial
	if mat:
		mat.initial_velocity_min = 3.0 + 5.0 * main_intensity
		mat.initial_velocity_max = 6.0 + 10.0 * main_intensity
		var color_scale = 1.0 if not _is_boosting else 1.8
		mat.scale_min = 0.1 * color_scale
		mat.scale_max = 0.3 * color_scale

	for t in [thruster_left, thruster_right]:
		t.amount = int(15 * _lateral_intensity)
		var tm = t.process_material as ParticleProcessMaterial
		if tm:
			tm.scale_min = 0.05 + 0.15 * _lateral_intensity

	if engine_accent_l and engine_accent_r:
		var mat_l = engine_accent_l.material_override as StandardMaterial3D
		var mat_r = engine_accent_r.material_override as StandardMaterial3D
		var glow = main_intensity * (2.0 if _is_boosting else 0.8)
		if mat_l:
			mat_l.emission_energy_multiplier = glow
		if mat_r:
			mat_r.emission_energy_multiplier = glow

func _update_camera(delta: float) -> void:
	if not spring_arm:
		return
	spring_arm.spring_length = lerp(spring_arm.spring_length, 12.0 if not _is_boosting else 18.0, delta * 2.0)

func _update_ghost_preview() -> void:
	if not _building_manager or not get_viewport():
		return
	var camera = get_viewport().get_camera_3d()
	if not camera:
		return
	var screen_center = get_viewport().size * 0.5
	var ray_origin = camera.project_ray_origin(screen_center)
	var ray_dir = camera.project_ray_normal(screen_center)
	_building_manager.update_ghost(ray_origin, ray_dir)

func get_ship_velocity() -> Vector3:
	return _velocity

func get_boost() -> float:
	return _boost

func get_is_boosting() -> bool:
	return _is_boosting

func get_cargo() -> Dictionary:
	return _cargo.duplicate()

func get_cargo_total() -> int:
	var t = 0
	for v in _cargo.values():
		t += v
	return t

func is_mining() -> bool:
	return _mining_active
