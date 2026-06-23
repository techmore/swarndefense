class_name Extractor
extends Building

func _ready() -> void:
	building_name = "Extractor"
	resource_costs = {"metal": 100, "crystal": 25}
	power_consumption = 10.0
	max_health = 150.0
	snap_offset = 4.0
	super._ready()

	build_mesh()
	add_collision()

func build_mesh() -> void:
	var platform = load_gltf_mesh("res://assets/quaternius/megakit/platforms/Platform_Metal.gltf", Vector3.ONE * 0.8)
	if platform:
		platform.position.y = -0.2
		add_child(platform)

	var column = load_gltf_mesh("res://assets/quaternius/megakit/columns/Column_Tall.gltf", Vector3.ONE * 0.5)
	if column:
		column.position.y = 0.5
		add_child(column)

	var vent = load_gltf_mesh("res://assets/quaternius/megakit/props/Prop_Vent_Big.gltf", Vector3.ONE * 0.8)
	if vent:
		vent.position.y = 1.5
		add_child(vent)

func add_collision() -> void:
	var coll = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(2.5, 4.0, 2.5)
	coll.shape = shape
	add_child(coll)

func create_base_material(color: Color) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.6
	mat.roughness = 0.4
	return mat
