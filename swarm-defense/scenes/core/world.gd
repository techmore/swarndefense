extends Node3D

@onready var celestial_system: Node3D = $CelestialSystem
@onready var camera_manager: Camera3D = $CameraManager
@onready var building_manager = $Buildings

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	GameManager.change_phase(GameManager.GamePhase.PLAYING)
	_setup_sky()
	_setup_starfield()
	_setup_celestial_bodies()
	_setup_asteroid_field()
	_spawn_player()
	_setup_hud()
	_setup_build_menu()
	_setup_options_panel()
	WaveManager.wave_ended.connect(_on_wave_ended)

func _setup_sky() -> void:
	var we = $WorldEnvironment
	if not we or not we.environment:
		return
	var sky = Sky.new()
	var mat = ShaderMaterial.new()
	var shader = load("res://scripts/shaders/space_sky.gdshader") as Shader
	if shader:
		mat.shader = shader
		sky.sky_material = mat
		we.environment.sky = sky
		we.environment.sky_custom_fov = 130.0
		we.environment.background_mode = Environment.BG_SKY
		if mat.has_method("set_shader_parameter"):
			mat.set_shader_parameter("star_density", 1.5)
			mat.set_shader_parameter("galaxy_brightness", 2.0)

func _setup_asteroid_field() -> void:
	var AsteroidFieldScript = load("res://scripts/systems/asteroid_field.gd")
	var field = AsteroidFieldScript.new()
	field.name = "AsteroidField"
	celestial_system.add_child(field)

func _setup_hud() -> void:
	var hud = preload("res://scenes/ui/ship_hud.tscn").instantiate()
	add_child(hud)

func _setup_build_menu() -> void:
	var menu = preload("res://scenes/ui/build_menu.tscn").instantiate()
	add_child(menu)

func _setup_starfield() -> void:
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = 4000
	mm.mesh = SphereMesh.new()
	mm.mesh.radius = 0.15
	mm.mesh.height = 0.3
	mm.mesh.rings = 1
	mm.mesh.radial_segments = 4

	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mm.mesh.surface_set_material(0, mat)

	var colors = PackedColorArray()
	colors.resize(mm.instance_count)
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
		var size = 0.3 + randf() * 1.8
		t = t.scaled(Vector3.ONE * size)
		mm.set_instance_transform(i, t)
		var color_v = 0.7 + randf() * 0.3
		var color = Color(color_v, color_v, 1.0)
		if randf() > 0.7:
			color = Color(color_v, color_v * 0.8, color_v * 0.6)
		colors[i] = color
	mm.color_array = colors

	var mmi = MultiMeshInstance3D.new()
	mmi.multimesh = mm
	add_child(mmi)

func _setup_celestial_bodies() -> void:
	var sun = preload("res://scenes/celestial/sun.tscn").instantiate()
	celestial_system.add_child(sun)

	var planet_scene = preload("res://scenes/celestial/planet.tscn")

	var earth_node: Node3D = null
	var planet_data = [
		{
			"name": "Mercury",
			"axis": 180, "period": 20.0, "radius": 3.0,
			"type": 0,
			"seed": 42, "freq": 6.0,
			"ecc": 0.05, "incl": 0.04, "rot": 58.0,
			"color": Color(0.6, 0.55, 0.5),
		},
		{
			"name": "Venus",
			"axis": 280, "period": 35.0, "radius": 6.0,
			"type": 1,
			"seed": 137, "freq": 2.0,
			"ecc": 0.03, "incl": 0.02, "rot": -240.0,
			"color": Color(0.9, 0.7, 0.4),
			"clouds": true,
			"cloud_speed": 0.03,
		},
		{
			"name": "Earth",
			"axis": 400, "period": 50.0, "radius": 7.0,
			"type": 2,
			"seed": 73, "freq": 2.5,
			"ecc": 0.02, "incl": 0.0, "rot": 1.0,
			"color": Color(0.2, 0.5, 0.8),
			"clouds": true,
			"cloud_speed": 0.02,
		},
		{
			"name": "Mars",
			"axis": 520, "period": 65.0, "radius": 5.0,
			"type": 3,
			"seed": 2048, "freq": 3.5,
			"ecc": 0.06, "incl": 0.03, "rot": 1.03,
			"color": Color(0.8, 0.3, 0.2),
		},
	]

	for data in planet_data:
		var planet = planet_scene.instantiate()
		planet.name = data["name"]
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
		if data.get("clouds", false):
			planet.has_clouds = true
			planet.cloud_speed = data.get("cloud_speed", 0.02)
		celestial_system.add_child(planet)
		if data["name"] == "Earth":
			earth_node = planet

	if earth_node:
		var moon = planet_scene.instantiate()
		moon.name = "Moon"
		moon.body_name = "Moon"
		moon.semi_major_axis = 18.0
		moon.orbital_period = 6.0
		moon.body_radius = 2.0
		moon.planet_type = 4
		moon.texture_seed = 999
		moon.noise_frequency = 5.0
		moon.eccentricity = 0.01
		moon.initial_angle = PI
		moon.color = Color(0.6, 0.58, 0.55)
		moon.has_atmosphere = false
		moon.show_orbit_trail = false
		earth_node.add_child(moon)

func _spawn_player() -> void:
	var ship = preload("res://scenes/ships/player_ship.tscn").instantiate() as Node3D
	ship.global_position = Vector3(412, 0, 0)
	$PlayerShips.add_child(ship)
	# Camera framing is handled by the intro sequence — don't force zoom here.
	if camera_manager and camera_manager.has_method("follow_target"):
		camera_manager.follow_target(ship.global_position)
	_start_intro(ship)

func _start_intro(ship: Node3D) -> void:
	var intro = load("res://scripts/systems/intro_sequence.gd").new()
	add_child(intro)
	intro.intro_finished.connect(_on_intro_finished)
	intro.begin(self, ship)

func _on_intro_finished() -> void:
	_spawn_swarm_patrol()

func _spawn_swarm_patrol() -> void:
	var count = 4 + randi() % 3
	for i in range(count):
		_spawn_swarm_unit(100.0 + randf() * 80.0, 8.0 + randf() * 6.0)

func _spawn_swarm_unit(dist: float, spd: float) -> void:
	var s = load("res://scripts/systems/swarm_unit.gd").new()
	var angle = randf() * TAU
	s.global_position = Vector3(380 + cos(angle) * dist, (randf() - 0.5) * 30.0, sin(angle) * dist)
	s.speed = spd
	add_child(s)
	WaveManager.on_enemy_spawned()
	s.killed.connect(_on_swarm_killed)

func _on_swarm_killed(_unit: Node) -> void:
	WaveManager.on_enemy_killed()
	if WaveManager.enemies_alive <= 0 and not WaveManager.wave_active and WaveManager.wave_number == 0:
		_on_patrol_cleared()

func _start_next_wave() -> void:
	if WaveManager.wave_active:
		return
	WaveManager.start_next_wave()
	var config = WaveManager.get_wave_config()
	var count = config.get("count", 5)
	var spawn_interval = config.get("spawn_interval", 1.5)
	_spawn_wave_units(count, spawn_interval)

func _spawn_wave_units(count: int, interval: float) -> void:
	for i in range(count):
		var dist = 150.0 + randf() * 100.0
		var spd = 10.0 + float(WaveManager.wave_number) * 2.0
		_spawn_swarm_unit(dist, spd)
		if i < count - 1:
			await get_tree().create_timer(interval).timeout

func _setup_options_panel() -> void:
	var opts = preload("res://scenes/ui/options_panel.tscn").instantiate()
	add_child(opts)

func _on_patrol_cleared() -> void:
	await get_tree().create_timer(3.0).timeout
	_start_next_wave()

func _on_wave_ended(_wave: int) -> void:
	if WaveManager.wave_number < WaveManager.waves_before_victory:
		await get_tree().create_timer(5.0).timeout
		_start_next_wave()
