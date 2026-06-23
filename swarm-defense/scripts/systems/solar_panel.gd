class_name SolarPanel
extends Building

func _ready() -> void:
	building_name = "Solar Panel"
	resource_costs = {"metal": 75, "crystal": 50}
	power_consumption = 0.0
	power_generation = 25.0
	max_health = 80.0
	snap_offset = 4.0
	super._ready()

	build_mesh()
	add_collision()

func build_mesh() -> void:
	var base = load_gltf_mesh("res://assets/quaternius/megakit/platforms/Platform_Simple.gltf", Vector3.ONE * 0.8)
	if base:
		base.position.y = -0.3
		add_child(base)

	var panel_mat = StandardMaterial3D.new()
	panel_mat.albedo_color = Color(0.15, 0.15, 0.3)
	panel_mat.metallic = 0.8
	panel_mat.roughness = 0.2
	panel_mat.emission_enabled = true
	panel_mat.emission = Color(0.1, 0.5, 1.0)
	panel_mat.emission_energy_multiplier = 0.5

	var panel = BoxMesh.new()
	panel.size = Vector3(0.08, 2.5, 2.5)
	panel.material = panel_mat

	var panel_mi = MeshInstance3D.new()
	panel_mi.mesh = panel
	panel_mi.position = Vector3(0, 1.5, 0)
	add_child(panel_mi)

	var stand = CylinderMesh.new()
	stand.top_radius = 0.1
	stand.bottom_radius = 0.15
	stand.height = 1.5
	stand.radial_segments = 6
	var stand_mat = StandardMaterial3D.new()
	stand_mat.albedo_color = Color(0.5, 0.5, 0.55)
	stand_mat.metallic = 0.7
	stand_mat.roughness = 0.3
	stand.material = stand_mat

	var stand_mi = MeshInstance3D.new()
	stand_mi.mesh = stand
	stand_mi.position.y = 0.8
	add_child(stand_mi)

func add_collision() -> void:
	var coll = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(0.5, 3.5, 3.5)
	coll.shape = shape
	add_child(coll)
