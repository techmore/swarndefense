extends CanvasLayer

@onready var speed_label: Label = $SpeedLabel
@onready var boost_bar_fill: ColorRect = $BoostBarOuter/BoostBarFill
@onready var cargo_label: Label = $CargoLabel
@onready var power_label: Label = $PowerLabel
@onready var battery_label: Label = $BatteryLabel
@onready var wave_label: Label = $WaveLabel
@onready var center_btn: Button = $CenterBtn
@onready var menu_btn: Button = $MenuBtn
@onready var mouse_hint: Label = $MouseHint

var _player_ship: Node = null
var _building_manager: Node = null
var _wave_label_state: String = ""
var _wave_label_timer: float = 0.0

func _ready() -> void:
	var ships = get_tree().get_nodes_in_group("player_ship")
	if ships.size() > 0:
		_player_ship = ships[0]
	_building_manager = get_tree().current_scene.find_child("Buildings", true, false)
	WaveManager.wave_started.connect(_on_wave_started)
	WaveManager.wave_ended.connect(_on_wave_ended)
	center_btn.pressed.connect(_on_center_pressed)
	menu_btn.pressed.connect(_on_menu_pressed)

func _on_center_pressed() -> void:
	var cam = get_viewport().get_camera_3d()
	if cam and cam.has_method("center_on_ship"):
		cam.center_on_ship()

func _on_menu_pressed() -> void:
	var opts = get_tree().current_scene.find_child("OptionsPanel", true, false)
	if opts and opts.has_method("toggle"):
		opts.toggle()

func _process(delta: float) -> void:
	if not _player_ship:
		return

	_update_ship_hud(delta)
	_update_power_hud()
	_update_wave_hud(delta)
	_update_mouse_hint()

func _update_ship_hud(delta: float) -> void:
	if _player_ship.has_method("get_ship_velocity"):
		var vel: Vector3 = _player_ship.get_ship_velocity()
		var speed = vel.length()
		speed_label.text = "%s km/s" % str(speed).pad_decimals(1)

	if _player_ship.has_method("get_boost"):
		var boost: float = _player_ship.get_boost()
		var pct = clamp(boost / 100.0, 0.0, 1.0)
		boost_bar_fill.anchor_right = pct
		var c = Color(0.1, 0.7 * pct + 0.3 * (1.0 - pct), 1.0 * pct + 0.3 * (1.0 - pct), 0.9)
		boost_bar_fill.color = c

	if _player_ship.has_method("get_cargo") and _player_ship.has_method("get_cargo_total"):
		var cargo = _player_ship.get_cargo()
		var total = _player_ship.get_cargo_total()
		var cap = _player_ship.cargo_capacity if "cargo_capacity" in _player_ship else 500
		var metal = cargo.get("metal", 0)
		var crystal = cargo.get("crystal", 0)
		cargo_label.text = "CARGO: %d/%d  [M:%d  C:%d]" % [total, cap, metal, crystal]

func _update_power_hud() -> void:
	if not _building_manager or not _building_manager.has_method("get_power_status"):
		return
	var p = _building_manager.get_power_status()
	if p.generation > 0 or p.consumption > 0:
		var net = p.generation - p.consumption
		var net_str = "%+.1f" % net
		var col = "#4fc" if net >= 0 else "#f44"
		power_label.text = "PWR: gen %.0f / con %.0f  [color=%s]%s[/color]" % [p.generation, p.consumption, col, net_str]
		power_label.visible = true
	else:
		power_label.visible = false

	if p.capacity > 0:
		var pct = p.stored / p.capacity * 100.0
		battery_label.text = "BAT: %.0f / %.0f  (%d%%)" % [p.stored, p.capacity, pct]
		battery_label.visible = true
	else:
		battery_label.visible = false

func _update_wave_hud(delta: float) -> void:
	if WaveManager.wave_active and WaveManager.wave_number > 0:
		wave_label.text = "WAVE %d ACTIVE" % WaveManager.wave_number
		wave_label.visible = true
	elif not WaveManager.wave_active and WaveManager.wave_number > 0:
		wave_label.text = "WAVE %d CLEARED" % WaveManager.wave_number
		if _wave_label_timer < 3.0:
			_wave_label_timer += delta
			wave_label.visible = true
		else:
			wave_label.visible = false
	else:
		wave_label.visible = false

func _on_wave_started(wave: int) -> void:
	_wave_label_timer = 0.0
	wave_label.text = "WAVE %d INCOMING" % wave
	wave_label.visible = true

func _on_wave_ended(wave: int) -> void:
	_wave_label_timer = 0.0

func _update_mouse_hint() -> void:
	if not mouse_hint:
		return
	var captured = Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	if captured:
		mouse_hint.text = "Esc = release cursor"
		mouse_hint.visible = true
	else:
		mouse_hint.visible = false
