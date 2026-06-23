class_name Battery
extends Building

func _ready() -> void:
	building_name = "Battery"
	resource_costs = {"metal": 50, "crystal": 75}
	power_storage = 200.0
	power_consumption = 0.0
	power_generation = 0.0
	max_health = 120.0
	snap_offset = 3.0
	super._ready()

	build_mesh()
	add_collision()

var power_storage: float = 200.0
var stored_power: float = 0.0
var glow_material: StandardMaterial3D

func build_mesh() -> void:
	var body_mat = StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.3, 0.3, 0.35)
	body_mat.metallic = 0.5
	body_mat.roughness = 0.5

	var body = BoxMesh.new()
	body.size = Vector3(2.0, 1.5, 2.0)
	body.material = body_mat

	var body_mi = MeshInstance3D.new()
	body_mi.mesh = body
	add_child(body_mi)

	glow_material = StandardMaterial3D.new()
	glow_material.albedo_color = Color(0.0, 0.6, 1.0)
	glow_material.emission_enabled = true
	glow_material.emission = Color(0.0, 0.6, 1.0)

	var glow = BoxMesh.new()
	glow.size = Vector3(0.6, 0.3, 0.6)
	glow.material = glow_material

	var glow_mi = MeshInstance3D.new()
	glow_mi.mesh = glow
	glow_mi.position = Vector3(0, 1.0, 0)
	add_child(glow_mi)

func add_collision() -> void:
	var coll = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(2.0, 1.5, 2.0)
	coll.shape = shape
	add_child(coll)

func store_power(amount: float) -> float:
	var capacity = stored_power + amount
	if capacity > power_storage:
		var excess = capacity - power_storage
		stored_power = power_storage
		return excess
	stored_power = capacity
	return 0.0

func draw_power(amount: float) -> float:
	if stored_power >= amount:
		stored_power -= amount
		return amount
	var available = stored_power
	stored_power = 0.0
	return available

func get_charge_percent() -> float:
	return clamp(stored_power / power_storage, 0.0, 1.0)
