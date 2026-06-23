extends Node

var music_player: AudioStreamPlayer
var sfx_bus: int

func _ready() -> void:
    music_player = AudioStreamPlayer.new()
    music_player.bus = "Music"
    add_child(music_player)
    sfx_bus = AudioServer.get_bus_index("SFX")

func play_sfx(stream: AudioStream, position: Vector3 = Vector3.ZERO) -> void:
    var player = AudioStreamPlayer3D.new()
    player.stream = stream
    player.bus = "SFX"
    player.global_position = position
    add_child(player)
    player.play()
    player.finished.connect(player.queue_free)

func play_music(stream: AudioStream, crossfade: float = 1.0) -> void:
    music_player.stream = stream
    music_player.play()

func stop_music(fade: float = 0.5) -> void:
    music_player.stop()

func set_master_volume(db: float) -> void:
    AudioServer.set_bus_volume_db(0, db)

func set_sfx_volume(db: float) -> void:
    AudioServer.set_bus_volume_db(sfx_bus, db)
