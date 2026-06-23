extends CharacterBody3D

@export var thrust_force: float = 50.0
@export var boost_multiplier: float = 3.0
@export var rotation_speed: float = 2.0
@export var max_speed: float = 200.0
@export var boost_drain: float = 10.0
@export var boost_regen: float = 5.0

var _velocity: Vector3 = Vector3.ZERO
var _boost: float = 100.0
var _is_boosting: bool = false

@onready var camera_pivot: Node3D = $CameraPivot
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm3D

func _enter_tree() -> void:
    if multiplayer.is_server():
        return
    _setup_camera()

func _setup_camera() -> void:
    pass

func _ready() -> void:
    if multiplayer.is_server():
        return

func _physics_process(delta: float) -> void:
    if not is_multiplayer_authority():
        return
    _handle_input(delta)
    _apply_movement(delta)

func _handle_input(delta: float) -> void:
    var input = InputHandler.get_movement_vector()
    var boost = InputHandler.get_boost_pressed()

    _is_boosting = boost and _boost > 0.0

    if input.length() > 0.0:
        var world_input = global_transform.basis * input
        var force = world_input * thrust_force * (boost_multiplier if _is_boosting else 1.0)
        _velocity += force * delta

    var mouse_motion = Input.get_last_mouse_velocity()
    if mouse_motion.length() > 0:
        rotate_y(-mouse_motion.x * 0.001)
        camera_pivot.rotate_x(-mouse_motion.y * 0.001)
        camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, -PI * 0.4, PI * 0.4)

func _apply_movement(delta: float) -> void:
    if _velocity.length() > max_speed:
        _velocity = _velocity.normalized() * max_speed

    var drag = _velocity * 0.01
    _velocity -= drag * delta

    velocity = _velocity
    move_and_slide()

    if _is_boosting:
        _boost = max(_boost - boost_drain * delta, 0.0)
    else:
        _boost = min(_boost + boost_regen * delta, 100.0)
