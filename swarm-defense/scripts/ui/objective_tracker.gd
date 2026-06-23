extends CanvasLayer

var objectives: Array[Dictionary] = []
var all_complete: bool = false
signal all_objectives_complete()

@onready var container: VBoxContainer = $Panel/Margin/VBox

func _ready() -> void:
	hide()

func set_objectives(objs: Array[Dictionary]) -> void:
	for c in container.get_children():
		c.queue_free()
	objectives = objs
	all_complete = false

	for o in objectives:
		var hbox = HBoxContainer.new()
		var check = Label.new()
		check.text = "[ ]"
		check.add_theme_color_override("font_color", Color(0.6, 0.2, 0.2))
		check.add_theme_font_size_override("font_size", 14)
		check.custom_minimum_size.x = 24
		hbox.add_child(check)
		o._check_label = check

		var label = Label.new()
		label.text = o.text
		label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.9, 0.8))
		label.add_theme_font_size_override("font_size", 13)
		hbox.add_child(label)

		var progress = Label.new()
		progress.text = " %s" % _progress_str(o)
		progress.add_theme_color_override("font_color", Color(0.5, 0.5, 0.7, 0.6))
		progress.add_theme_font_size_override("font_size", 11)
		hbox.add_child(progress)
		o._progress_label = progress

		container.add_child(hbox)

func _progress_str(o: Dictionary) -> String:
	var cur = o.get("current", 0)
	var need = o.get("needed", 1)
	return "%d/%d" % [cur, need]

func update_objective(key: String, amount: int = 1) -> void:
	for o in objectives:
		if o.key == key and not o.get("done", false):
			o.current = o.get("current", 0) + amount
			if o.has("_progress_label"):
				o._progress_label.text = " %s" % _progress_str(o)
			if o.current >= o.needed:
				o.done = true
				if o.has("_check_label"):
					o._check_label.text = "[x]"
					o._check_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.4))
	_check_all()

func _check_all() -> void:
	for o in objectives:
		if not o.get("done", false):
			return
	all_complete = true
	all_objectives_complete.emit()
