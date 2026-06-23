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

@export var planet_type: PlanetTextureGenerator.PlanetType = PlanetTextureGenerator.PlanetType.EARTH
@export var texture_seed: int = 0
@export var noise_frequency: float = 3.0
@export var show_orbit_trail: bool = true
@export var has_atmosphere: bool = true

var _time: float = 0.0
var _mesh_instance: MeshInstance3D
var _atmosphere_instance: MeshInstance3D
var _orbit_trail: MeshInstance3D

func _ready() -> void:
    _setup_mesh()
    _setup_atmosphere()
    if show_orbit_trail:
        _setup_orbit_trail()

func _setup_mesh() -> void:
    _mesh_instance = MeshInstance3D.new()
    var sphere = SphereMesh.new()
    sphere.radius = body_radius
    sphere.height = body_radius * 2.0
    sphere.subdivide_depth = 4
    sphere.subdivide_width = 5

    var material = StandardMaterial3D.new()
    if texture_seed != 0:
        var texture = PlanetTextureGenerator.generate_texture(planet_type, texture_seed, noise_frequency)
        material.albedo_texture = texture
        material.albedo_color = Color.WHITE
    else:
        material.albedo_color = color
    material.metallic = 0.1
    material.roughness = 0.85
    material.texture_filter = 1

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

func _setup_atmosphere() -> void:
    if not has_atmosphere:
        return
    var atmo_color = PlanetTextureGenerator.get_atmosphere_color(planet_type)
    if atmo_color.a <= 0.0:
        return

    _atmosphere_instance = MeshInstance3D.new()
    var atmo_sphere = SphereMesh.new()
    atmo_sphere.radius = body_radius * 1.08
    atmo_sphere.height = body_radius * 2.16
    atmo_sphere.subdivide_depth = 3
    atmo_sphere.subdivide_width = 4

    var atmo_mat = StandardMaterial3D.new()
    atmo_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    atmo_mat.albedo_color = Color(atmo_color.r, atmo_color.g, atmo_color.b, 0.08)
    atmo_mat.emission_enabled = true
    atmo_mat.emission = Color(atmo_color.r, atmo_color.g, atmo_color.b) * 0.3
    atmo_mat.cull_mode = BaseMaterial3D.CULL_BACK
    atmo_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

    _atmosphere_instance.mesh = atmo_sphere
    _atmosphere_instance.material_override = atmo_mat
    _atmosphere_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(_atmosphere_instance)

func _setup_orbit_trail() -> void:
    _orbit_trail = MeshInstance3D.new()
    _orbit_trail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(_orbit_trail)
    _rebuild_orbit_trail()

func _rebuild_orbit_trail() -> void:
    var steps = 128
    var points: PackedVector3Array = []
    for i in range(steps + 1):
        var t = orbital_period * float(i) / float(steps)
        points.append(_get_orbital_position(t))

    var st = SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_LINE_STRIP)
    var trail_color = Color(body_name.hash(), 0.4, 0.6, 0.3)
    for p in points:
        st.set_color(trail_color)
        st.set_uv(Vector2.ZERO)
        st.add_vertex(p)
    _orbit_trail.mesh = st.commit()

func _process(delta: float) -> void:
    if TimeManager:
        _time += delta * TimeManager.simulation_speed
    else:
        _time += delta
    position = _get_orbital_position(_time)
    rotation.y += (2.0 * PI / rotation_period) * delta

    if _atmosphere_instance:
        _atmosphere_instance.rotation.y += (2.0 * PI / rotation_period) * delta * 0.5

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
