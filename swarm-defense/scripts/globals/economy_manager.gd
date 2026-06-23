extends Node

class ResourceEntry:
    var amount: int = 0
    var capacity: int = 0
    var income_rate: float = 0.0

var _resources: Dictionary = {}

signal resource_changed(resource_type: String, new_amount: int)
signal resource_depleted(resource_type: String)

func _ready() -> void:
    _resources["metal"] = ResourceEntry.new()
    _resources["crystal"] = ResourceEntry.new()
    _resources["power"] = ResourceEntry.new()
    _resources["food"] = ResourceEntry.new()

func add_resource(type: String, amount: int, source: String = "") -> int:
    if not _resources.has(type):
        return 0
    var entry = _resources[type]
    var added = min(amount, entry.capacity - entry.amount) if entry.capacity > 0 else amount
    entry.amount += added
    resource_changed.emit(type, entry.amount)
    return added

func spend_resource(type: String, amount: int) -> bool:
    if not _resources.has(type):
        return false
    var entry = _resources[type]
    if entry.amount < amount:
        return false
    entry.amount -= amount
    resource_changed.emit(type, entry.amount)
    if entry.amount <= 0:
        resource_depleted.emit(type)
    return true

func get_amount(type: String) -> int:
    return _resources.get(type, ResourceEntry.new()).amount

func set_capacity(type: String, capacity: int) -> void:
    if _resources.has(type):
        _resources[type].capacity = max(capacity, 0)

func set_income_rate(type: String, rate: float) -> void:
    if _resources.has(type):
        _resources[type].income_rate = rate

func _on_income_tick() -> void:
    for type in _resources:
        var entry = _resources[type]
        if entry.income_rate > 0:
            add_resource(type, int(entry.income_rate), "income_tick")
