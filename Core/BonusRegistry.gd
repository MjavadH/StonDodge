extends Node

##- Export Variables ----------------------------------------------------------##
@export var all_bonuses: Array[BonusData]

##- Private Variables ---------------------------------------------------------##
# A dictionary mapping bonus IDs to their data for fast O(1) lookups.
var _bonus_map: Dictionary = {}

##- Godot Engine Functions ----------------------------------------------------##
func _ready() -> void:
	for bonus_data: BonusData in all_bonuses:
		if bonus_data and bonus_data.bonus_type != &"":
			_bonus_map[bonus_data.bonus_type] = bonus_data

##- Public API ----------------------------------------------------------------##

# Returns the data for a specific bonus by its ID.
# Returns null if the ID is not found.
func get_bonus_data(id: StringName) -> BonusData:
	return _bonus_map.get(id, null)

# Returns a random bonus from the entire list of available bonuses.
func get_random_bonus() -> BonusData:
	if all_bonuses.is_empty():
		return null
	return all_bonuses.pick_random()

# Returns a random bonus from a specific, provided list of IDs.
func get_random_bonus_from(id_list: Array[StringName]) -> BonusData:
	var valid_bonuses: Array[BonusData] = []
	for id: StringName in id_list:
		if _bonus_map.has(id):
			valid_bonuses.append(_bonus_map[id])
	
	if valid_bonuses.is_empty():
		return null
	return valid_bonuses.pick_random()

func get_random_weighted_bonus() -> BonusData:
	if all_bonuses.is_empty():
		return null

	var total_weight: int = 0
	for bonus: BonusData in all_bonuses:
		total_weight += bonus.weight
	
	if total_weight <= 0:
		return all_bonuses.pick_random()

	var random_roll: int = randi() % total_weight
	
	var cumulative_weight: int = 0
	for bonus: BonusData in all_bonuses:
		cumulative_weight += bonus.weight
		if random_roll < cumulative_weight:
			return bonus # This is our chosen bonus.
			
	return all_bonuses.back()

func get_random_weighted_bonus_from_dict(weighted_dict: Dictionary) -> BonusData:
	if weighted_dict.is_empty():
		return null

	var total_weight: int = 0
	for id in weighted_dict:
		total_weight += weighted_dict[id]
	
	if total_weight <= 0:
		return null

	var random_roll: int = randi() % total_weight
	
	var cumulative_weight: int = 0
	for id in weighted_dict:
		cumulative_weight += weighted_dict[id]
		if random_roll < cumulative_weight:
			return get_bonus_data(id)
			
	return null
