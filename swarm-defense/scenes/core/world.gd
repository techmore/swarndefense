extends Node3D

@onready var celestial_system: Node3D = $CelestialSystem
@onready var camera_manager: Camera3D = $CameraManager

func _ready() -> void:
	GameManager.change_phase(GameManager.GamePhase.PLAYING)
	_setup_starfield()
	_setup_celestial_bodies()
	_spawn_player()
	_setup_hud()

func _setup_hud() -> void:
	var hud = preload("res://scenes/ui/ship_hud.tscn").instantiate()
	add_child(hud)

func _setup_starfield() -> void:
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = 2000
	mm.mesh = SphereMesh.new()
	mm.mesh.radius = 0.15
	mm.mesh.height = 0.3
	mm.mesh.subdivide_depth = 0
	mm.mesh.subdivide_width = 0

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.9, 1.0, 1)
	mat.emission_enabled = true
	mat.emission = Color(0.9, 0.9, 1.0)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mm.mesh.surface_set_material(0, mat)

	for i in range(mm.instance_count):
		var t = Transform3D.IDENTITY
		var theta = randf() * TAU
		var phi = acos(2.0 * randf() - 1.0)
		var r = 3000.0 + randf() * 4000.0
		t.origin = Vector3(
			r * sin(phi) * cos(theta),
			r * cos(phi),
			r * sin(phi) * sin(theta)
		)
		t = t.scaled(Vector3.ONE * (0.5 + randf() * 1.5))
		mm.set_instance_transform(i, t)

	var mmi = MultiMeshInstance3D.new()
	mmi.multimesh = mm
	add_child(mmi)

func _setup_celestial_bodies() -> void:
	var sun = preload("res://scenes/celestial/sun.tscn").instantiate()
	celestial_system.add_child(sun)

	var planet_scene = preload("res://scenes/celestial/planet.tscn")

	var planet_data = [
		{
			"name": "Mercury",
			"axis": 180, "period": 20.0, "radius": 3.0,
			"type": PlanetTextureGenerator.PlanetType.MERCURY,
			"seed": 42, "freq": 6.0,
			"ecc": 0.05, "incl": 0.04, "rot": 58.0,
			"color": Color(0.6, 0.55, 0.5),
		},
		{
			"name": "Venus",
			"axis": 280, "period": 35.0, "radius": 6.0,
			"type": PlanetTextureGenerator.PlanetType.VENUS,
			"seed": 137, "freq": 2.0,
			"ecc": 0.03, "incl": 0.02, "rot": -240.0,
			"color": Color(0.9, 0.7, 0.4),
		},
		{
			"name": "Earth",
			"axis": 400, "period": 50.0, "radius": 7.0,
			"type": PlanetTextureGenerator.PlanetType.EARTH,
			"seed": 73, "freq": 2.5,
			"ecc": 0.02, "incl": 0.0, "rot": 1.0,
			"color": Color(0.2, 0.5, 0.8),
		},
		{
			"name": "Mars",
			"axis": 520, "period": 65.0, "radius": 5.0,
			"type": PlanetTextureGenerator.PlanetType.MARS,
			"seed": 2048, "freq": 3.5,
			"ecc": 0.06, "incl": 0.03, "rot": 1.03,
			"color": Color(0.8, 0.3, 0.2),
		},
	]

	for data in planet_data:
		var planet = planet_scene.instantiate()
		planet.body_name = data["name"]
		planet.semi_major_axis = data["axis"]
		planet.orbital_period = data["period"]
		planet.body_radius = data["radius"]
		planet.planet_type = data["type"]
		planet.texture_seed = data["seed"]
		planet.noise_frequency = data["freq"]
		planet.eccentricity = data["ecc"]
		planet.inclination = data["incl"]
		planet.rotation_period = data["rot"]
		planet.color = data["color"]
		planet.show_orbit_trail = true
		celestial_system.add_child(planet)

	var moon = planet_scene.instantiate()
	moon.body_name = "Moon"
	moon.semi_major_axis = 18.0
	moon.orbital_period = 6.0
	moon.body_radius = 2.0
	moon.planet_type = PlanetTextureGenerator.PlanetType.MOON
	moon.texture_seed = 999
	moon.noise_frequency = 5.0
	moon.eccentricity = 0.01
	moon.initial_angle = PI
	moon.color = Color(0.6, 0.58, 0.55)
	moon.has_atmosphere = false
	moon.show_orbit_trail = false
	celestial_system.get_node("Earth").add_child(moon)

func _spawn_player() -> void:
	var ship = preload("res://scenes/ships/player_ship.tscn").instantiate()
	ship.global_position = Vector3(450, 20, 0)
	$PlayerShips.add_child(ship)
