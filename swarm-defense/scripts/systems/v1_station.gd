class_name V1Station
extends Building

func _ready() -> void:
	building_name = "V1 Station"
	resource_costs = {"metal": 500, "crystal": 200}
	power_consumption = 0.0
	power_generation = 0.0
	max_health = 800.0
	snap_offset = 8.0
	super._ready()
	build_mesh()
	add_collision()

var ring_mi: MeshInstance3D
var hub_mi: MeshInstance3D
var glow_mi: MeshInstance3D

func build_mesh() -> void:
	var center = load_gltf_mesh("res://assets/quaternius/megakit/platforms/Platform_Round1.gltf", Vector3.ONE * 1.2)
	if center:
		add_child(center)

	var column = load_gltf_mesh("res://assets/quaternius/megakit/columns/Column_Large_Straight.gltf", Vector3.ONE * 0.8)
	if column:
		column.position.y = 0.3
		add_child(column)

	var spokes = 6
	for i in range(spokes):
		var a = float(i) / float(spokes) * TAU
		var wall = load_gltf_mesh("res://assets/quaternius/megakit/walls/WallAstra_Straight.gltf", Vector3.ONE * 0.6)
		if wall:
			wall.position = Vector3(cos(a) * 3.0, 0.5, sin(a) * 3.0)
			wall.rotation.y = -a
			add_child(wall)
		var beam = BoxMesh.new()
		beam.size = Vector3(0.1, 0.1, 3.5)
		var beam_mat = StandardMaterial3D.new()
		beam_mat.albedo_color = Color(0.35, 0.38, 0.42)
		beam_mat.metallic = 0.7
		beam_mat.roughness = 0.3
		beam.material = beam_mat
		var beam_mi = MeshInstance3D.new()
		beam_mi.mesh = beam
		beam_mi.position = Vector3(cos(a) * 1.8, 0.5, sin(a) * 1.8)
		beam_mi.look_at(Vector3.ZERO, Vector3.UP)
		add_child(beam_mi)

	var glow_mat = StandardMaterial3D.new()
	glow_mat.albedo_color = Color(0.1, 0.5, 1.0)
	glow_mat.emission_enabled = true
	glow_mat.emission = Color(0.1, 0.5, 1.0) * 1.5
	glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	glow_mi = MeshInstance3D.new()
	glow_mi.mesh = SphereMesh.new()
	glow_mi.mesh.radius = 0.2
	glow_mi.mesh.height = 0.4
	glow_mi.material_override = glow_mat
	glow_mi.position = Vector3(0, 0.8, 0)
	add_child(glow_mi)

func add_collision() -> void:
	var coll = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.radius = 3.5
	shape.height = 2.5
	coll.shape = shape
	add_child(coll)
