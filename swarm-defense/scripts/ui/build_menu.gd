class_name BuildMenu
extends CanvasLayer

var building_types: Array[Dictionary] = []
var selected_index: int = -1
var menu_active: bool = false

signal building_selected(building_type: Dictionary)
signal menu_closed()

@onready var center: Control = $Center
@onready var options_container: Node = $Center/Options

func _ready() -> void:
	hide()
	building_types = [
		{"name": "Extractor", "scene": "res://scenes/buildings/extractor.tscn", "costs": {"metal": 100, "crystal": 25}, "icon": null},
		{"name": "Solar Panel", "scene": "res://scenes/buildings/solar_panel.tscn", "costs": {"metal": 75, "crystal": 50}, "icon": null},
		{"name": "Battery", "scene": "res://scenes/buildings/battery.tscn", "costs": {"metal": 50, "crystal": 75}, "icon": null},
		{"name": "Turret", "scene": "res://scenes/buildings/turret.tscn", "costs": {"metal": 200, "crystal": 100}, "icon": null},
	]

func show_menu() -> void:
	menu_active = true
	show()
	_populate_options()

func hide_menu() -> void:
	menu_active = false
	hide()
	menu_closed.emit()

func _populate_options() -> void:
	for c in options_container.get_children():
		c.queue_free()

	var count = building_types.size()
	var radius = 120.0
	var angle_step = TAU / count
	var start_angle = -PI / 2.0

	for i in range(count):
		var btype = building_types[i]
		var angle = start_angle + i * angle_step

		var btn = Button.new()
		btn.text = btype["name"] + "\n" + _format_costs(btype["costs"])
		btn.size = Vector2(100, 60)
		btn.position = Vector2(
			center.size.x / 2.0 + cos(angle) * radius - 50.0,
			center.size.y / 2.0 + sin(angle) * radius - 30.0
		)

		if not _can_afford(btype["costs"]):
			btn.disabled = true
			btn.modulate = Color(0.4, 0.4, 0.4, 0.6)

		btn.pressed.connect(_on_option_selected.bind(i))
		options_container.add_child(btn)

func _format_costs(costs: Dictionary) -> String:
	var parts: Array[String] = []
	for rtype in costs:
		parts.append(str(costs[rtype]) + " " + rtype)
	return ", ".join(parts)

func _can_afford(costs: Dictionary) -> bool:
	for rtype in costs:
		if EconomyManager.get_amount(rtype) < costs[rtype]:
			return false
	return true

func _on_option_selected(index: int) -> void:
	if index < 0 or index >= building_types.size():
		return
	if not _can_afford(building_types[index]["costs"]):
		return
	selected_index = index
	building_selected.emit(building_types[index])
	hide_menu()

func _input(event: InputEvent) -> void:
	if not menu_active:
		return
	if event.is_action_pressed("build_menu") or event.is_action_pressed("ui_cancel"):
		hide_menu()
		get_viewport().set_input_as_handled()
