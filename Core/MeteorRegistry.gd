extends Node

@export var regular_meteor_types: Array[MeteorData]
@export var special_meteor_types: Array[MeteorData]
@export var bonus_meteor_types: Array[MeteorData]

# Public functions to get a random meteor data from a specific category.
func get_random_regular_meteor() -> MeteorData:
	if regular_meteor_types.is_empty(): return null
	return regular_meteor_types.pick_random()

func get_random_bonus_meteor() -> MeteorData:
	if bonus_meteor_types.is_empty(): return null
	return bonus_meteor_types.pick_random()

func get_random_special_meteor() -> MeteorData:
	if special_meteor_types.is_empty(): return null
	return special_meteor_types.pick_random()
	
# ... you can add more functions for other types if needed.
