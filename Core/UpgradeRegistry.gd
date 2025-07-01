extends Node

##- Export Variables ----------------------------------------------------------##
@export var available_upgrades: Array[UpgradeData]

##- Private Variables ---------------------------------------------------------##
var _upgrade_map: Dictionary = {}

##- Godot Engine Functions ----------------------------------------------------##
func _ready() -> void:
	for upgrade in available_upgrades:
		if upgrade and upgrade.id != &"":
			_upgrade_map[upgrade.id] = upgrade
##- Public API ----------------------------------------------------------------##

func get_upgrade_data(id: StringName) -> UpgradeData:
	return _upgrade_map.get(id, null)
