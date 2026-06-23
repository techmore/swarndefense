extends Node

var _buildings: Array[Node] = []

signal building_placed(building: Node)
signal building_destroyed(building: Node)

func place_building(scene: PackedScene, position: Vector3, rotation_y: float) -> Node:
    var building = scene.instantiate()
    add_child(building)
    building.global_position = position
    building.rotation.y = rotation_y
    _buildings.append(building)
    building_placed.emit(building)
    return building

func remove_building(building: Node) -> void:
    if building in _buildings:
        _buildings.erase(building)
        building_destroyed.emit(building)
        building.queue_free()

func get_buildings_in_radius(center: Vector3, radius: float) -> Array[Node]:
    var result: Array[Node] = []
    for b in _buildings:
        if b.global_position.distance_to(center) <= radius:
            result.append(b)
    return result

func get_building_count() -> int:
    return _buildings.size()
