extends Node3D

var team: int = 1
var health: float = 30.0
var speed: float = 12.0
var contact_damage: float = 5.0
var resource_drop: Dictionary = {"metal": 5}
var velocity: Vector3 = Vector3.ZERO
var _target: Node3D = null

signal killed(unit: Node)

static var _model_paths: Array[String] = [
	"res://assets/quaternius/aliens/Alien_Cyclop.gltf",
	"res://assets/quaternius/aliens/Alien_Oculichrysalis.gltf",
	"res://assets/quaternius/aliens/Alien_Scolitex.gltf",
	"res://assets/quaternius/ships/Omen.gltf",
	"res://assets/quaternius/ships/Insurgent.gltf",
]

func _ready() -> void:
	add_to_group("swarm")
	_setup_hitbox()
	_load_model()

func _setup_hitbox() -> void:
	var area = Area3D.new()
	area.name = "Hitbox"
	var coll = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 1.0
	coll.shape = shape
	area.add_child(coll)
	add_child(area)
	area.body_entered.connect(_on_body_entered)

func _load_model() -> void:
	var idx = randi() % _model_paths.size()
	var path = _model_paths[idx]
	var scene = load(path) as PackedScene
	if not scene:
		_generate_fallback_mesh()
		return
	var instance = scene.instantiate() as Node3D
	if instance:
		instance.name = "SwarmModel"
		var s = 0.3 + randf() * 0.4
		instance.scale = Vector3.ONE * s
		add_child(instance)

func _generate_fallback_mesh() -> void:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.15, 0.1)
	mat.metallic = 0.3
	mat.roughness = 0.4
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.2, 0.1) * 0.8

	var bodies = 5
	for i in range(bodies):
		var sphere = MeshInstance3D.new()
		sphere.mesh = SphereMesh.new()
		sphere.mesh.radius = 0.3 + randf() * 0.3
		sphere.mesh.height = sphere.mesh.radius * 2.0
		sphere.mesh.rings = 2
		sphere.mesh.radial_segments = 6
		var a = randf() * TAU
		var r = 0.5 + randf() * 0.5
		sphere.position = Vector3(cos(a) * r, (randf() - 0.5) * 0.5, sin(a) * r)
		sphere.material_override = mat
		add_child(sphere)

	var core_mat = StandardMaterial3D.new()
	core_mat.albedo_color = Color(1.0, 0.3, 0.15)
	core_mat.emission_enabled = true
	core_mat.emission = Color(1.0, 0.4, 0.2) * 1.5
	core_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	var core = MeshInstance3D.new()
	core.mesh = SphereMesh.new()
	core.mesh.radius = 0.25
	core.mesh.height = 0.5
	core.mesh.rings = 2
	core.mesh.radial_segments = 8
	core.material_override = core_mat
	core.position = Vector3.ZERO
	add_child(core)

func _physics_process(delta: float) -> void:
	_find_target()
	if _target:
		var dir = (_target.global_position - global_position).normalized()
		velocity = dir * speed
		look_at(global_position + velocity, Vector3.UP)
	global_position += velocity * delta

func _find_target() -> void:
	if _target and is_instance_valid(_target):
		return
	_target = null
	var nearest_dist = 200.0
	var player_ships = get_tree().get_nodes_in_group("player_ship")
	if player_ships.size() > 0:
		var d = global_position.distance_to(player_ships[0].global_position)
		if d < nearest_dist:
			nearest_dist = d
			_target = player_ships[0]
	var buildings = get_tree().get_nodes_in_group("buildings")
	for b in buildings:
		var d = global_position.distance_to(b.global_position)
		if d < nearest_dist:
			nearest_dist = d
			_target = b

func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		body.take_damage(contact_damage, self)

func take_damage(amount: float, attacker: Node = null) -> void:
	health -= amount
	if health <= 0:
		_die()

func _die() -> void:
	for rtype in resource_drop:
		EconomyManager.add_resource(rtype, resource_drop[rtype], "swarm_kill")
	killed.emit(self)
	queue_free()
