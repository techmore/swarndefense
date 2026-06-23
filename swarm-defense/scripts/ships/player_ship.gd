extends CharacterBody3D

@export var thrust_force: float = 60.0
@export var boost_multiplier: float = 3.0
@export var rotation_speed: float = 3.0
@export var max_speed: float = 150.0
@export var max_boost_speed: float = 350.0
@export var boost_drain: float = 12.0
@export var boost_regen: float = 6.0
@export var linear_drag: float = 0.4
@export var angular_drag: float = 4.0

var _velocity: Vector3 = Vector3.ZERO
var _angular_velocity: Vector3 = Vector3.ZERO
var _boost: float = 100.0
var _is_boosting: bool = false
var _mouse_captured: bool = false
var _throttle: float = 0.0
var _lateral_intensity: float = 0.0

@onready var camera_pivot: Node3D = $CameraPivot
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var thruster_main: GPUParticles3D = $ThrusterMain
@onready var thruster_left: GPUParticles3D = $ThrusterLeft
@onready var thruster_right: GPUParticles3D = $ThrusterRight
@onready var headlight: OmniLight3D = $Headlight
@onready var engine_accent_l: MeshInstance3D = $EngineAccentLeft
@onready var engine_accent_r: MeshInstance3D = $EngineAccentRight

func _ready() -> void:
    add_to_group("player_ship")
    _setup_thrusters()

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
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        if not _mouse_captured:
            Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
            _mouse_captured = true
    if event.is_action_pressed("pause"):
        if _mouse_captured:
            Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
            _mouse_captured = false

func _physics_process(delta: float) -> void:
    _handle_input(delta)
    _apply_movement(delta)
    _update_thrusters(delta)
    _update_camera(delta)

func _handle_input(delta: float) -> void:
    var input = InputHandler.get_movement_vector()
    var boost = Input.is_action_pressed("boost")

    _is_boosting = boost and _boost > 0.0

    _throttle = -input.z
    _lateral_intensity = Vector2(input.x, input.y).length()

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

func _integrate_mouse_motion(event: InputEventMouseMotion) -> void:
    if _mouse_captured:
        _angular_velocity.y -= event.relative.x * 0.002
        _angular_velocity.x -= event.relative.y * 0.002

func get_velocity() -> Vector3:
    return _velocity

func get_boost() -> float:
    return _boost

func get_is_boosting() -> bool:
    return _is_boosting
