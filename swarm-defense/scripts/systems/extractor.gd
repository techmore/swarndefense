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
	var base = BoxMesh.new()
	base.size = Vector3(2.5, 1.0, 2.5)
	base.material = create_base_material(Color(0.4, 0.4, 0.5))

	var base_mi = MeshInstance3D.new()
	base_mi.mesh = base
	add_child(base_mi)

	var arm = BoxMesh.new()
	arm.size = Vector3(0.3, 2.5, 0.3)
	arm.material = create_base_material(Color(0.6, 0.55, 0.4))

	var arm_mi = MeshInstance3D.new()
	arm_mi.mesh = arm
	arm_mi.position = Vector3(0, 2.0, 0)
	add_child(arm_mi)

	var drill = CylinderMesh.new()
	drill.top_radius = 0.5
	drill.bottom_radius = 1.2
	drill.height = 1.0
	drill.radial_segments = 8
	drill.material = create_base_material(Color(0.7, 0.4, 0.2))

	var drill_mi = MeshInstance3D.new()
	drill_mi.mesh = drill
	drill_mi.position = Vector3(0, 3.3, 0)
	add_child(drill_mi)

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
