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

enum PlanetType { MERCURY, VENUS, EARTH, MARS, MOON, GAS_GIANT, ICE_WORLD, LAVA_WORLD }

@export var planet_type: int = PlanetType.EARTH
@export var texture_seed: int = 0
@export var noise_frequency: float = 3.0
@export var show_orbit_trail: bool = true
@export var has_atmosphere: bool = true
@export var use_disk_texture: bool = true
@export var has_clouds: bool = false
@export var cloud_speed: float = 0.02

var _time: float = 0.0
var _mesh_instance: MeshInstance3D
var _clouds_instance: MeshInstance3D
var _atmosphere_instance: MeshInstance3D
var _orbit_trail: MeshInstance3D

func _ready() -> void:
	_setup_mesh()
	_setup_clouds()
	_setup_atmosphere()
	if show_orbit_trail:
		_setup_orbit_trail()

func _get_texture_path(name_suffix: String) -> String:
	var name = body_name.to_lower()
	var path = "res://assets/textures/planets/%s_%s.jpg" % [name, name_suffix]
	if ResourceLoader.exists(path):
		return path
	path = "res://assets/textures/planets/%s_%s.png" % [name, name_suffix]
	if ResourceLoader.exists(path):
		return path
	return ""

func _setup_mesh() -> void:
	_mesh_instance = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = body_radius
	sphere.height = body_radius * 2.0
	sphere.rings = 10
	sphere.radial_segments = 16

	var material = StandardMaterial3D.new()

	if use_disk_texture:
		var tex_path = _get_texture_path("albedo")
		if not tex_path.is_empty():
			var tex = load(tex_path) as Texture2D
			if tex:
				material.albedo_texture = tex
				material.albedo_color = Color.WHITE
				material.roughness = 0.9
				material.metallic = 0.0
				material.texel_size = 0.001
				return _finalize_mesh(sphere, material)

	if texture_seed != 0:
		var PTG = load("res://scripts/systems/planet_texture_generator.gd")
		var texture = PTG.generate_texture(planet_type, texture_seed, noise_frequency)
		material.albedo_texture = texture
		material.albedo_color = Color.WHITE
	else:
		material.albedo_color = color
	material.metallic = 0.1
	material.roughness = 0.85
	material.texture_filter = 1

	_finalize_mesh(sphere, material)

func _finalize_mesh(sphere: SphereMesh, material: StandardMaterial3D) -> void:
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

func _setup_clouds() -> void:
	if not has_clouds:
		return

	var cloud_path = _get_texture_path("clouds")
	if cloud_path.is_empty():
		return

	var cloud_tex = load(cloud_path) as Texture2D
	if not cloud_tex:
		return

	_clouds_instance = MeshInstance3D.new()
	var cloud_sphere = SphereMesh.new()
	cloud_sphere.radius = body_radius * 1.02
	cloud_sphere.height = body_radius * 2.04
	cloud_sphere.rings = 8
	cloud_sphere.radial_segments = 14

	var cloud_mat = StandardMaterial3D.new()
	cloud_mat.albedo_texture = cloud_tex
	cloud_mat.albedo_color = Color(1, 1, 1, 0.6)
	cloud_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cloud_mat.cull_mode = BaseMaterial3D.CULL_BACK
	cloud_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	_clouds_instance.mesh = cloud_sphere
	_clouds_instance.material_override = cloud_mat
	_clouds_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_clouds_instance)

func _setup_atmosphere() -> void:
	if not has_atmosphere:
		return
	var PTG = load("res://scripts/systems/planet_texture_generator.gd")
	var atmo_color = PTG.get_atmosphere_color(planet_type)
	if atmo_color.a <= 0.0:
		return

	_atmosphere_instance = MeshInstance3D.new()
	var atmo_sphere = SphereMesh.new()
	atmo_sphere.radius = body_radius * 1.08
	atmo_sphere.height = body_radius * 2.16
	atmo_sphere.rings = 6
	atmo_sphere.radial_segments = 10

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

	if _clouds_instance:
		_clouds_instance.rotation.y += cloud_speed * delta

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
