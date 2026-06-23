extends CanvasLayer

var is_open: bool = false

signal options_closed()

@onready var panel: Control = $Panel
@onready var center_btn: Button = $Panel/VBox/CenterShip
@onready var volume_slider: HSlider = $Panel/VBox/VolumeSlider
@onready var resume_btn: Button = $Panel/VBox/Resume

func _ready() -> void:
	hide()
	process_mode = PROCESS_MODE_ALWAYS
	center_btn.pressed.connect(_on_center)
	volume_slider.value_changed.connect(_on_volume_changed)
	resume_btn.pressed.connect(_on_resume)

func toggle() -> void:
	if is_open:
		close()
	else:
		open()

func open() -> void:
	is_open = true
	show()
	# Reflect the actual master volume instead of forcing full volume on every open.
	var db = AudioManager.get_master_volume()
	volume_slider.value = clamp((db + 80.0) / 80.0, 0.0, 1.0)
	get_tree().paused = true

func close() -> void:
	is_open = false
	hide()
	get_tree().paused = false
	options_closed.emit()

func _on_center() -> void:
	var cam = get_viewport().get_camera_3d()
	if cam and cam.has_method("center_on_ship"):
		cam.center_on_ship()

func _on_volume_changed(value: float) -> void:
	var db = -80.0 + value * 80.0
	AudioManager.set_master_volume(db)

func _on_resume() -> void:
	close()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_TAB and event.is_pressed():
		toggle()
		get_viewport().set_input_as_handled()
		return
	if not is_open:
		return
	if event.is_action_pressed("pause") or (event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed):
		close()
		get_viewport().set_input_as_handled()
