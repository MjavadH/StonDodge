class_name ShipData
extends Resource

##- Identification ------------------------------------------------------------##
@export var id: StringName

##- Display & Shop Information ------------------------------------------------##
@export_group("Display & Shop")
@export var ship_name: String
@export var icon: Texture2D
@export var cost: int = 1000

##- Game Data -----------------------------------------------------------------##
@export_group("Game Data")
@export var ship_scene: PackedScene

##- Available Upgrades --------------------------------------------------------##
# A list of upgrade IDs that are available for THIS specific ship.
# These IDs will be used to get the full UpgradeData from the UpgradeRegistry.
@export_group("Upgrades")
@export var available_upgrade_ids: Array[StringName]
