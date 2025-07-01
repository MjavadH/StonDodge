extends Node

@export var available_ships: Array[ShipData]

var _ship_map: Dictionary = {}

func _ready() -> void:
	for ship_data in available_ships:
		if ship_data and ship_data.id != &"":
			_ship_map[ship_data.id] = ship_data

func get_ship_data(id: StringName) -> ShipData:
	return _ship_map.get(id, null)
