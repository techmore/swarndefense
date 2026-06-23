extends CanvasLayer

@onready var speed_label: Label = $SpeedLabel
@onready var boost_bar_fill: ColorRect = $BoostBarOuter/BoostBarFill
@onready var cargo_label: Label = $CargoLabel

var _player_ship: Node = null

func _ready() -> void:
	var ships = get_tree().get_nodes_in_group("player_ship")
	if ships.size() > 0:
		_player_ship = ships[0]

func _process(delta: float) -> void:
	if not _player_ship:
		return

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
		var cap = _player_ship.cargo_capacity if _player_ship.has_property("cargo_capacity") else 500
		var metal = cargo.get("metal", 0)
		var crystal = cargo.get("crystal", 0)
		cargo_label.text = "CARGO: %d/%d  [M:%d  C:%d]" % [total, cap, metal, crystal]
