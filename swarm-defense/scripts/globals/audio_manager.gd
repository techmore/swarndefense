extends Node

var music_player: AudioStreamPlayer
var sfx_bus: int
var _fade_tween: Tween

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
	if music_player.stream == stream and music_player.playing:
		return

	if music_player.playing and crossfade > 0.0:
		# Fade out the current track, then start the new one.
		_kill_fade_tween()
		_fade_tween = create_tween()
		_fade_tween.tween_property(music_player, "volume_db", -40.0, crossfade)
		_fade_tween.tween_callback(func():
			music_player.stop()
			music_player.stream = stream
			music_player.volume_db = -40.0
			music_player.play())
		_fade_tween.tween_property(music_player, "volume_db", 0.0, crossfade)
	else:
		music_player.stream = stream
		music_player.volume_db = 0.0
		music_player.play()

func stop_music(fade: float = 0.5) -> void:
	if fade > 0.0:
		_kill_fade_tween()
		_fade_tween = create_tween()
		_fade_tween.tween_property(music_player, "volume_db", -40.0, fade)
		_fade_tween.tween_callback(music_player.stop)
	else:
		music_player.stop()

func set_master_volume(db: float) -> void:
	AudioServer.set_bus_volume_db(0, db)

func set_sfx_volume(db: float) -> void:
	AudioServer.set_bus_volume_db(sfx_bus, db)

func get_master_volume() -> float:
	return AudioServer.get_bus_volume_db(0)

func _kill_fade_tween() -> void:
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
