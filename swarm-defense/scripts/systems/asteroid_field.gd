class_name AsteroidField
extends Node3D

class AsteroidData:
	var instance_idx: int
	var position: Vector3
	var resources: Dictionary  # type -> amount
	var max_resources: int
	var depleted: bool = false
	var scale: float

const ASTEROID_COUNT := 300
const BELT_INNER := 600.0
const BELT_OUTER := 950.0
const BELT_HEIGHT := 60.0

var _asteroids: Array[AsteroidData] = []
var _multi_mesh: MultiMesh
var _mesh_instance: MultiMeshInstance3D

func _ready() -> void:
	_generate_field()

func _generate_field() -> void:
	var base_mesh = SphereMesh.new()
	base_mesh.radius = 1.0
	base_mesh.height = 2.0
	base_mesh.rings = 3
	base_mesh.radial_segments = 5

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.30, 0.25)
	mat.roughness = 0.9
	mat.metallic = 0.1
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	base_mesh.surface_set_material(0, mat)

	_multi_mesh = MultiMesh.new()
	_multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
	_multi_mesh.mesh = base_mesh
	_multi_mesh.instance_count = ASTEROID_COUNT

	var rng = RandomNumberGenerator.new()
	rng.seed = 42

	for i in range(ASTEROID_COUNT):
		var data = AsteroidData.new()
		data.instance_idx = i

		var angle = rng.randf_range(0.0, TAU)
		var dist = rng.randf_range(BELT_INNER, BELT_OUTER)
		var height = rng.randf_range(-BELT_HEIGHT, BELT_HEIGHT)
		data.position = Vector3(
			dist * cos(angle),
			height,
			dist * sin(angle)
		)

		data.scale = rng.randf_range(0.5, 3.0)
		data.max_resources = int(rng.randf_range(20, 100))
		data.resources = {
			"metal": int(data.max_resources * rng.randf_range(0.4, 1.0)),
			"crystal": int(data.max_resources * rng.randf_range(0.0, 0.4)),
		}

		var t = Transform3D.IDENTITY
		t.origin = data.position
		t = t.scaled(Vector3.ONE * data.scale)
		t = t.rotated(Vector3.RIGHT, rng.randf_range(0.0, TAU))
		t = t.rotated(Vector3.UP, rng.randf_range(0.0, TAU))
		_multi_mesh.set_instance_transform(i, t)

		var color_variation = Color(
			rng.randf_range(0.3, 0.5),
			rng.randf_range(0.25, 0.4),
			rng.randf_range(0.15, 0.3)
		)
		var cdata = PackedColorArray([color_variation])
		_multi_mesh.set_instance_color(i, color_variation)

		_asteroids.append(data)

	_mesh_instance = MultiMeshInstance3D.new()
	_mesh_instance.multimesh = _multi_mesh
	add_child(_mesh_instance)

func mine_asteroid(global_hit: Vector3, damage: int = 1) -> Dictionary:
	var collected = {}
	var local_hit = to_local(global_hit)
	var closest: AsteroidData = null
	var closest_dist = 10.0

	for a in _asteroids:
		if a.depleted:
			continue
		var d = local_hit.distance_to(a.position)
		if d < closest_dist:
			closest_dist = d
			closest = a

	if not closest:
		return collected

	var range_threshold = closest.scale * 2.5
	if closest_dist > range_threshold:
		return collected

	for rtype in closest.resources:
		var extract = min(damage, closest.resources[rtype])
		if extract > 0:
			closest.resources[rtype] -= extract
			collected[rtype] = collected.get(rtype, 0) + extract

	var total_remaining = 0
	for val in closest.resources.values():
		total_remaining += val

	if total_remaining <= 0:
		closest.depleted = true
		_hide_asteroid(closest.instance_idx)

	return collected

func _hide_asteroid(idx: int) -> void:
	var t = _multi_mesh.get_instance_transform(idx)
	t = t.scaled(Vector3.ZERO)
	_multi_mesh.set_instance_transform(idx, t)

func get_asteroid_count() -> int:
	var count = 0
	for a in _asteroids:
		if not a.depleted:
			count += 1
	return count
