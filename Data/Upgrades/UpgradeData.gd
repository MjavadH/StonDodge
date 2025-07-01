class_name UpgradeData
extends Resource

##- Identification ------------------------------------------------------------##
# A unique identifier used to reference this upgrade in code.
# Example: &"health_upgrade", &"firerate_boost"
@export var id: StringName

##- Display & Shop Information ------------------------------------------------##
@export_group("Display & Shop")
@export var icon: Texture2D

##- Gameplay Data -------------------------------------------------------------##
@export_group("Gameplay Data")
# The core mechanics of the upgrade.
@export var max_level: int = 5

# Defines the cost for each level. The size of this array should match 'max_level'.
# Example for 5 levels: [1000, 2500, 5000, 10000, 20000]
# Level 1 costs 1000, Level 2 costs 2500, etc.
@export var cost_per_level: Array[int]
@export var value_per_level: Array 
