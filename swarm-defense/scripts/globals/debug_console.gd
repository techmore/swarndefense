extends Node

@tool

var _history: Array[String] = []
var _visible: bool = false

func _ready() -> void:
    if not OS.is_debug_build():
        queue_free()

func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.keycode == KEY_QUOTELEFT and event.pressed:
        _visible = not _visible
        get_viewport().set_input_as_handled()

func log_message(msg: String) -> void:
    _history.append(msg)
    print("[Debug] ", msg)

func spawn_entity(scene_path: String, position: Vector3) -> void:
    var scene = load(scene_path)
    if scene:
        var instance = scene.instantiate()
        get_tree().current_scene.add_child(instance)
        instance.global_position = position
        log_message("Spawned: " + scene_path)
