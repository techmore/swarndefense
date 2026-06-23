extends Camera3D

enum ZoomLevel { SYSTEM, PLANETARY, SURFACE }

var current_zoom: ZoomLevel = ZoomLevel.SYSTEM
var _follow_target: Vector3 = Vector3.ZERO
var _pan_offset: Vector3 = Vector3.ZERO
var target_position: Vector3 = Vector3.ZERO
var zoom_distance: float = 1000.0
var _rotation_h: float = 0.0
var _rotation_v: float = -1.0

@export var system_distance: float = 1500.0
@export var planetary_distance: float = 100.0
@export var surface_distance: float = 10.0
@export var rotate_speed: float = 0.003
@export var zoom_speed: float = 0.1
@export var follow_smoothing: float = 5.0
@export var pan_speed: float = 60.0
@export var pan_return_speed: float = 3.0

func _ready() -> void:
	current_zoom = ZoomLevel.SYSTEM
	zoom_distance = system_distance
	make_current()
	var ships = get_tree().get_nodes_in_group("player_ship")
	if ships.size() > 0:
		_follow_target = ships[0].global_position
		target_position = _follow_target

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		_rotation_h -= event.relative.x * rotate_speed
		_rotation_v -= event.relative.y * rotate_speed
		_rotation_v = clamp(_rotation_v, -PI * 0.45, PI * 0.05)

	if event.is_action("zoom_in"):
		zoom_distance *= (1.0 - zoom_speed)
		_update_zoom_level()
	if event.is_action("zoom_out"):
		zoom_distance *= (1.0 + zoom_speed)
		_update_zoom_level()

	if event.is_action("center_camera") and event.is_pressed():
		_pan_offset = Vector3.ZERO
		target_position = _follow_target

func _update_zoom_level() -> void:
	if zoom_distance > system_distance * 0.6:
		current_zoom = ZoomLevel.SYSTEM
	elif zoom_distance > planetary_distance * 0.6:
		current_zoom = ZoomLevel.PLANETARY
	else:
		current_zoom = ZoomLevel.SURFACE

func _physics_process(delta: float) -> void:
	_follow_target = _find_ship()
	_handle_pan(delta)

	var offset = Vector3.ZERO
	offset.x = zoom_distance * cos(_rotation_h) * cos(_rotation_v)
	offset.z = zoom_distance * sin(_rotation_h) * cos(_rotation_v)
	offset.y = zoom_distance * sin(_rotation_v)

	var desired_pos = target_position + offset
	global_position = global_position.lerp(desired_pos, delta * follow_smoothing)
	look_at(target_position)

func _handle_pan(delta: float) -> void:
	var mouse_captured = Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	if mouse_captured:
		_pan_offset = _pan_offset.lerp(Vector3.ZERO, delta * 8.0)
		if _pan_offset.length() < 0.1:
			_pan_offset = Vector3.ZERO
		target_position = _follow_target + _pan_offset
		return

	var input = Vector3.ZERO
	if Input.is_action_pressed("move_left"):
		input.x -= 1.0
	if Input.is_action_pressed("move_right"):
		input.x += 1.0
	if Input.is_action_pressed("move_forward"):
		input.z -= 1.0
	if Input.is_action_pressed("move_back"):
		input.z += 1.0

	if input.length() > 0.0:
		input = input.normalized()
		var camera_basis = global_transform.basis
		var flat_right = camera_basis.x * Vector3(1, 0, 1)
		var flat_forward = -camera_basis.z * Vector3(1, 0, 1)
		if flat_right.length() > 0.01:
			flat_right = flat_right.normalized()
		if flat_forward.length() > 0.01:
			flat_forward = flat_forward.normalized()
		var world_move = flat_right * input.x + flat_forward * input.z
		_pan_offset += world_move * pan_speed * delta
		target_position = _follow_target + _pan_offset
	else:
		_pan_offset = _pan_offset.lerp(Vector3.ZERO, delta * pan_return_speed)
		if _pan_offset.length() < 0.5:
			_pan_offset = Vector3.ZERO
		target_position = _follow_target + _pan_offset

func _find_ship() -> Vector3:
	var ships = get_tree().get_nodes_in_group("player_ship")
	if ships.size() > 0:
		return ships[0].global_position
	return _follow_target

func center_on_ship() -> void:
	_pan_offset = Vector3.ZERO
	target_position = _follow_target

func follow_target(new_target: Vector3) -> void:
	_follow_target = new_target
	target_position = _follow_target + _pan_offset

func focus_on_planet(planet_position: Vector3, zoom: ZoomLevel = ZoomLevel.PLANETARY) -> void:
	_follow_target = planet_position
	_pan_offset = Vector3.ZERO
	target_position = _follow_target
	current_zoom = zoom
	match zoom:
		ZoomLevel.PLANETARY:
			zoom_distance = planetary_distance
		ZoomLevel.SURFACE:
			zoom_distance = surface_distance
		_:
			zoom_distance = system_distance
