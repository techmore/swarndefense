class_name Turret
extends Building

func _ready() -> void:
	building_name = "Turret"
	resource_costs = {"metal": 200, "crystal": 100}
	power_consumption = 30.0
	max_health = 200.0
	snap_offset = 3.0
	super._ready()

	targeting_range = 80.0
	damage = 15.0
	fire_rate = 0.5

	build_mesh()
	add_collision()

var targeting_range: float = 80.0
var damage: float = 15.0
var fire_rate: float = 0.5
var _cooldown: float = 0.0
var _barrel: MeshInstance3D
var _target: Node3D = null

func build_mesh() -> void:
	var base_mat = StandardMaterial3D.new()
	base_mat.albedo_color = Color(0.4, 0.35, 0.3)
	base_mat.metallic = 0.6
	base_mat.roughness = 0.4

	var base = CylinderMesh.new()
	base.top_radius = 1.0
	base.bottom_radius = 1.5
	base.height = 0.6
	base.radial_segments = 12
	base.material = base_mat

	var base_mi = MeshInstance3D.new()
	base_mi.mesh = base
	add_child(base_mi)

	var turret_mat = StandardMaterial3D.new()
	turret_mat.albedo_color = Color(0.5, 0.45, 0.4)
	turret_mat.metallic = 0.6
	turret_mat.roughness = 0.3

	var turret = CylinderMesh.new()
	turret.top_radius = 0.6
	turret.bottom_radius = 0.8
	turret.height = 1.0
	turret.radial_segments = 12
	turret.material = turret_mat

	var turret_mi = MeshInstance3D.new()
	turret_mi.mesh = turret
	turret_mi.position = Vector3(0, 0.8, 0)
	add_child(turret_mi)

	var barrel_mat = StandardMaterial3D.new()
	barrel_mat.albedo_color = Color(0.3, 0.3, 0.3)
	barrel_mat.metallic = 0.8
	barrel_mat.roughness = 0.2

	var barrel = CylinderMesh.new()
	barrel.top_radius = 0.1
	barrel.bottom_radius = 0.15
	barrel.height = 2.0
	barrel.radial_segments = 8
	barrel.material = barrel_mat

	_barrel = MeshInstance3D.new()
	_barrel.mesh = barrel
	_barrel.position = Vector3(0, 1.5, 1.0)
	add_child(_barrel)

func add_collision() -> void:
	var coll = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.radius = 1.5
	shape.height = 2.5
	coll.shape = shape
	add_child(coll)

func get_fire_point() -> Vector3:
	return _barrel.global_position + _barrel.global_transform.basis.z * -1.8

func _process(delta: float) -> void:
	if not is_placed:
		return
	_cooldown = max(_cooldown - delta, 0.0)
	_find_target()
	if _target:
		_aim_at(_target)
		if _cooldown <= 0.0:
			_fire()

func _find_target() -> void:
	if _target and is_instance_valid(_target):
		if global_position.distance_to(_target.global_position) <= targeting_range:
			return
	_target = null
	var nearest_dist = targeting_range
	var swarm = get_tree().get_nodes_in_group("swarm")
	for s in swarm:
		var d = global_position.distance_to(s.global_position)
		if d < nearest_dist:
			nearest_dist = d
			_target = s

func _aim_at(target: Node3D) -> void:
	var dir = (target.global_position - _barrel.global_position).normalized()
	_barrel.look_at(_barrel.global_position + dir, Vector3.UP)

func _fire() -> void:
	if not _target or not is_instance_valid(_target):
		return
	_cooldown = 1.0 / fire_rate
	var proj = Projectile.new()
	var fire_dir = (_target.global_position - _barrel.global_position).normalized()
	proj.setup(get_fire_point(), fire_dir, "buildings")
	proj.damage = damage
	proj.speed = 80.0
	get_tree().current_scene.add_child(proj)
