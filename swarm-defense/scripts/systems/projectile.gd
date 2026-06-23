class_name Projectile
extends Area3D

var speed: float = 60.0
var damage: float = 10.0
var _direction: Vector3 = Vector3.FORWARD
var _lifetime: float = 3.0
var _age: float = 0.0
var _owner_group: String = ""

func _ready() -> void:
	body_entered.connect(_on_hit)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.8, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.1, 0.6, 1.0) * 2.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	var mesh = MeshInstance3D.new()
	mesh.mesh = SphereMesh.new()
	mesh.mesh.radius = 0.15
	mesh.mesh.height = 0.3
	mesh.material_override = mat
	add_child(mesh)

	var coll = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 0.3
	coll.shape = shape
	add_child(coll)

func setup(origin: Vector3, direction: Vector3, owner_group: String = "player_ship") -> void:
	global_position = origin
	_direction = direction.normalized()
	_owner_group = owner_group

func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= _lifetime:
		queue_free()
		return
	global_position += _direction * speed * delta

func _on_hit(body: Node) -> void:
	if body.is_in_group(_owner_group):
		return
	if body.has_method("take_damage"):
		body.take_damage(damage, self)
		queue_free()
