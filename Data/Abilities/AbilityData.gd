class_name AbilityData
extends Resource

##- Identification ------------------------------------------------------------##
# A unique identifier used to reference this ability in code.
# e.g., &"shield", &"dash_boost", &"emp_blast"
@export var id: StringName

##- Display & UI Information --------------------------------------------------##
@export_group("Display & UI")
@export var display_name: String
# The icon for the ability button in the HUD.
@export var icon: Texture2D

##- Gameplay Data -------------------------------------------------------------##
@export_group("Gameplay Data")
# The cooldown time in seconds after the ability is used.
@export var cooldown_duration: float = 10.0
