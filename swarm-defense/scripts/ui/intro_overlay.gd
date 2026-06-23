extends CanvasLayer

@onready var text_label: Label = $TextLabel
@onready var subtitle: Label = $Subtitle
@onready var bg: ColorRect = $BgRect

func _ready() -> void:
	hide()

func play_intro() -> void:
	show()
	bg.modulate = Color.BLACK
	text_label.text = ""
	subtitle.text = ""

	var tw = create_tween().set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(bg, "modulate", Color(0, 0, 0, 0.7), 1.5)
	await tw.finished

	await _flash_text("SWARM DETECTED", 2.5)
	await _wait(0.8)

	await _flash_text("DEFENSE POSTURING...", 2.0)

func play_swarm_engaged() -> void:
	await _flash_text("AUTOMATED DEFENSES ENGAGED", 1.5)

func play_swarm_neutralized() -> void:
	await _flash_text("SWARM THREAT NEUTRALIZED", 2.0)
	await _wait(1.0)

func play_objective(text: String) -> void:
	text_label.text = text
	text_label.modulate = Color(1, 1, 1, 0)
	var tw = create_tween()
	tw.tween_property(text_label, "modulate", Color(1, 1, 1, 1), 0.8)
	await tw.finished
	await _wait(4.0)

func play_outro() -> void:
	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(text_label, "modulate", Color(1, 1, 1, 0), 0.8)
	tw.tween_property(subtitle, "modulate", Color(1, 1, 1, 0), 0.8)
	tw.tween_property(bg, "modulate", Color(0, 0, 0, 0), 1.2)
	await tw.finished
	hide()

func _flash_text(text: String, hold: float) -> void:
	text_label.text = text
	text_label.modulate = Color(1, 1, 1, 0)
	var tw = create_tween()
	tw.tween_property(text_label, "modulate", Color(1, 1, 1, 1), 0.6)
	await tw.finished
	await _wait(hold)

func subtitle_text(text: String) -> void:
	subtitle.text = text
	subtitle.modulate.a = 1.0

func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout
