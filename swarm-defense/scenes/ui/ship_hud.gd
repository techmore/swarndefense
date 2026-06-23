extends CanvasLayer

@onready var speed_label: Label = $SpeedLabel
@onready var boost_bar_fill: ColorRect = $BoostBarOuter/BoostBarFill

var _player_ship: Node = null

func _ready() -> void:
    var ships = get_tree().get_nodes_in_group("player_ship")
    if ships.size() > 0:
        _player_ship = ships[0]

func _process(delta: float) -> void:
    if not _player_ship or not _player_ship.has_method("get_velocity"):
        return
    var vel: Vector3 = _player_ship.get_velocity()
    var speed = vel.length()
    var boost: float = _player_ship.get_boost()

    speed_label.text = "%s km/s" % str(speed).pad_decimals(1)

    var pct = clamp(boost / 100.0, 0.0, 1.0)
    boost_bar_fill.anchor_right = pct
    var c = Color(0.1, 0.7 * pct + 0.3 * (1.0 - pct), 1.0 * pct + 0.3 * (1.0 - pct), 0.9)
    boost_bar_fill.color = c
