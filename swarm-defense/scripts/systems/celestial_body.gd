extends Node3D

@export var body_name: String = "Unnamed"
@export var body_radius: float = 10.0
@export var orbital_period: float = 60.0
@export var semi_major_axis: float = 200.0
@export var eccentricity: float = 0.05
@export var inclination: float = 0.0
@export var initial_angle: float = 0.0
@export var rotation_period: float = 10.0
@export var color: Color = Color.WHITE
@export var orbit_color: Color = Color.GRAY

var _time: float = 0.0
var _mesh_instance: MeshInstance3D
var _orbit_lines: Array[Vector3] = []

func _ready() -> void:
    _setup_mesh()
    _generate_orbit_path()

func _setup_mesh() -> void:
    _mesh_instance = MeshInstance3D.new()
    var sphere = SphereMesh.new()
    sphere.radius = body_radius
    sphere.height = body_radius * 2.0
    sphere.subdivide_depth = 2
    sphere.subdivide_width = 3

    var material = StandardMaterial3D.new()
    material.albedo_color = color
    material.metallic = 0.1
    material.roughness = 0.8
    _mesh_instance.mesh = sphere
    _mesh_instance.material_override = material
    add_child(_mesh_instance)

    var collision = CollisionShape3D.new()
    var shape = SphereShape3D.new()
    shape.radius = body_radius * 1.5
    collision.shape = shape
    add_child(collision)

    var area = Area3D.new()
    area.add_child(collision.duplicate())
    add_child(area)

func _generate_orbit_path() -> void:
    _orbit_lines.clear()
    var steps = 64
    for i in range(steps + 1):
        var t = orbital_period * float(i) / float(steps)
        _orbit_lines.append(_get_orbital_position(t))

func _process(delta: float) -> void:
    if TimeManager:
        _time += delta * TimeManager.simulation_speed
    else:
        _time += delta
    position = _get_orbital_position(_time)
    rotation.y += (2.0 * PI / rotation_period) * delta

func _get_orbital_position(t: float) -> Vector3:
    var angle = 2.0 * PI * t / orbital_period + initial_angle
    var x = semi_major_axis * cos(angle)
    var z = semi_major_axis * sin(angle) * sqrt(1.0 - eccentricity * eccentricity)
    return Vector3(x, sin(angle) * inclination * 10.0, z)

func get_orbital_velocity(t: float) -> Vector3:
    var dt = 0.01
    var p1 = _get_orbital_position(t)
    var p2 = _get_orbital_position(t + dt)
    return (p2 - p1) / dt

func get_forward_direction() -> Vector3:
    var velocity = get_orbital_velocity(_time)
    if velocity.length() < 0.001:
        return Vector3.FORWARD
    return velocity.normalized()
