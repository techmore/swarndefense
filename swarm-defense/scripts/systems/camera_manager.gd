extends Camera3D

enum ZoomLevel { SYSTEM, PLANETARY, SURFACE }

var current_zoom: ZoomLevel = ZoomLevel.SYSTEM
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

func _ready() -> void:
    current_zoom = ZoomLevel.SYSTEM
    zoom_distance = system_distance
    make_current()

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

func _update_zoom_level() -> void:
    if zoom_distance > system_distance * 0.6:
        current_zoom = ZoomLevel.SYSTEM
    elif zoom_distance > planetary_distance * 0.6:
        current_zoom = ZoomLevel.PLANETARY
    else:
        current_zoom = ZoomLevel.SURFACE

func _physics_process(delta: float) -> void:
    var offset = Vector3.ZERO
    offset.x = zoom_distance * cos(_rotation_h) * cos(_rotation_v)
    offset.z = zoom_distance * sin(_rotation_h) * cos(_rotation_v)
    offset.y = zoom_distance * sin(_rotation_v)

    var desired_pos = target_position + offset
    global_position = global_position.lerp(desired_pos, delta * follow_smoothing)
    look_at(target_position)

func follow_target(new_target: Vector3) -> void:
    target_position = new_target

func focus_on_planet(planet_position: Vector3, zoom: ZoomLevel = ZoomLevel.PLANETARY) -> void:
    target_position = planet_position
    current_zoom = zoom
    match zoom:
        ZoomLevel.PLANETARY:
            zoom_distance = planetary_distance
        ZoomLevel.SURFACE:
            zoom_distance = surface_distance
        _:
            zoom_distance = system_distance
