extends Node3D

@export var solar_radius: float = 25.0

var _rotation_speed: float = 0.02
var _pulse_time: float = 0.0

func _ready() -> void:
    _setup_texture()
    _setup_corona()

func _setup_texture() -> void:
    var noise = FastNoiseLite.new()
    noise.seed = 1
    noise.noise_type = FastNoiseLite.TYPE_PERLIN
    noise.frequency = 1.5
    noise.fractal_type = FastNoiseLite.FRACTAL_FBM
    noise.fractal_octaves = 4
    noise.fractal_gain = 0.5

    var image = Image.create(256, 128, false, Image.FORMAT_RGBA8)
    for y in range(image.get_height()):
        for x in range(image.get_width()):
            var u = float(x) / float(image.get_width())
            var v = float(y) / float(image.get_height())
            var n = noise.get_noise_2d(u * 6.0, v * 3.0) * 0.5 + 0.5
            var c = Color(
                1.0,
                0.7 + n * 0.25,
                0.1 + n * 0.2,
                1.0
            )
            image.set_pixel(x, y, c)

    var texture = ImageTexture.create_from_image(image)

    var mesh_instance = $Mesh as MeshInstance3D
    if mesh_instance and mesh_instance.material_override is StandardMaterial3D:
        var mat = mesh_instance.material_override as StandardMaterial3D
        mat.albedo_texture = texture

func _process(delta: float) -> void:
    _pulse_time += delta
    var pulse = 1.0 + sin(_pulse_time * 0.5) * 0.03
    var mesh_instance = $Mesh as MeshInstance3D
    if mesh_instance:
        mesh_instance.rotation.y += _rotation_speed * delta
        mesh_instance.scale = Vector3(pulse, pulse, pulse)

var _corona_particles: GPUParticles3D

func _setup_corona() -> void:
    _corona_particles = $Corona as GPUParticles3D
    if not _corona_particles:
        return

    var particle_mat = ParticleProcessMaterial.new()
    particle_mat.direction = Vector3.UP
    particle_mat.spread = 180.0
    particle_mat.initial_velocity_min = 1.0
    particle_mat.initial_velocity_max = 3.0
    particle_mat.lifetime_randomness = 0.5
    particle_mat.gravity = Vector3.ZERO
    particle_mat.scale_min = 0.5
    particle_mat.scale_max = 2.0
    particle_mat.color = Color(1.0, 0.8, 0.3, 0.4)

    _corona_particles.process_material = particle_mat
    _corona_particles.emitting = true

func get_sun_position() -> Vector3:
    return global_position

func get_power_at_distance(distance: float) -> float:
    if distance <= 0:
        return 0.0
    var max_range = 5000.0
    var t = 1.0 - clamp(distance / max_range, 0.0, 1.0)
    return t * t
