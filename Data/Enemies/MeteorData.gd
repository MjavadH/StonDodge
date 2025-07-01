class_name MeteorData
extends Resource

@export var texture: Texture2D
@export var health: int = 1
@export var score_value: int = 1
# The name of the explosion animation for this meteor type.
@export var explosion_anim_name: StringName = &"OrangeMeteor"

@export var crack_color: Color = Color(0.23,0.13,0.05,1)

# Does this meteor have a chance to drop a bonus?
@export var is_bonus_carrier: bool = false
