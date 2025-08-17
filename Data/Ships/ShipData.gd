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
@export_group("Upgrades")
@export var available_upgrade_ids: Array[StringName]

##- Abilities -----------------------------------------------------------------##=
@export_group("Abilities")
@export var abilities: Array[AbilityData]

##- Compatible Bonuses --------------------------------------------------------##
@export_group("Bonuses")
@export var compatible_bonuses: Dictionary = {}
