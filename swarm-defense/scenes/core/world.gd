extends Node3D

@onready var celestial_system: Node3D = $CelestialSystem
@onready var camera_manager: Camera3D = $CameraManager

func _ready() -> void:
    GameManager.change_phase(GameManager.GamePhase.PLAYING)
    _setup_celestial_bodies()
    _spawn_player()

func _setup_celestial_bodies() -> void:
    var sun = preload("res://scenes/celestial/sun.tscn").instantiate()
    celestial_system.add_child(sun)

    var planet_scene = preload("res://scenes/celestial/planet.tscn")

    var planet_data = [
        {"name": "Mercury", "axis": 180, "period": 20.0, "radius": 3.0, "color": Color(0.6, 0.55, 0.5), "ecc": 0.05},
        {"name": "Venus",   "axis": 280, "period": 35.0, "radius": 6.0, "color": Color(0.9, 0.7, 0.4), "ecc": 0.03},
        {"name": "Earth",   "axis": 400, "period": 50.0, "radius": 7.0, "color": Color(0.2, 0.5, 0.8), "ecc": 0.02},
        {"name": "Mars",    "axis": 520, "period": 65.0, "radius": 5.0, "color": Color(0.8, 0.3, 0.2), "ecc": 0.06},
    ]

    for data in planet_data:
        var planet = planet_scene.instantiate()
        planet.body_name = data["name"]
        planet.semi_major_axis = data["axis"]
        planet.orbital_period = data["period"]
        planet.body_radius = data["radius"]
        planet.color = data["color"]
        planet.eccentricity = data["ecc"]
        celestial_system.add_child(planet)

    var moon = planet_scene.instantiate()
    moon.body_name = "Moon"
    moon.semi_major_axis = 20.0
    moon.orbital_period = 8.0
    moon.body_radius = 2.0
    moon.color = Color(0.6, 0.58, 0.55)
    moon.eccentricity = 0.01
    moon.initial_angle = PI
    celestial_system.get_node("Earth").add_child(moon)

func _spawn_player() -> void:
    var ship = preload("res://scenes/ships/player_ship.tscn").instantiate()
    ship.global_position = Vector3(450, 0, 0)
    $PlayerShips.add_child(ship)
