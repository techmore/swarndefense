extends Node

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS

func is_action_just_pressed(action: String) -> bool:
    return Input.is_action_just_pressed(action)

func is_action_pressed(action: String) -> bool:
    return Input.is_action_pressed(action)

func get_movement_vector() -> Vector3:
    var input = Vector3.ZERO
    if Input.is_action_pressed("move_forward"):
        input.z -= 1.0
    if Input.is_action_pressed("move_back"):
        input.z += 1.0
    if Input.is_action_pressed("move_left"):
        input.x -= 1.0
    if Input.is_action_pressed("move_right"):
        input.x += 1.0
    if Input.is_action_pressed("move_up"):
        input.y += 1.0
    if Input.is_action_pressed("move_down"):
        input.y -= 1.0
    return input.normalized()

func get_boost_pressed() -> bool:
    return Input.is_action_just_pressed("boost")

func get_fire_pressed() -> bool:
    return Input.is_action_pressed("primary_fire")
