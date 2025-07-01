# The GameManager (Autoload).
extends Node

##- Signals -------------------------------------------------------------------##
signal total_score_updated(new_total_score: int)
signal current_score_updated(new_current_score: int)
signal score_multiplier_changed(new_multiplier: int)

##- Constants -----------------------------------------------------------------##
const SAVE_FILE_PATH: String = "user://player_data.save"

const _DEFAULT_SETTINGS: Dictionary = {
	"Music": true,
	"Language": "en"
}
const DEFAULT_SHIP_ID: StringName = &"default"

##- Game State Variables ------------------------------------------------------##
# Scores
var _high_score: int = 0
var _total_score: int = 0  # This is the persistent currency for upgrades.
var _current_game_score: int = 0 # Resets every round.
var _score_multiplier: int = 1

# Equipment
var _equipped_ship_id: StringName = DEFAULT_SHIP_ID
var _owned_ship_ids: Array[StringName] = [DEFAULT_SHIP_ID]

# Upgrades & Settings
var _upgrade_levels: Dictionary = {}
var _current_settings: Dictionary = {}

##- Godot Engine Functions ----------------------------------------------------##

func _ready() -> void:
	_load_data()

func _notification(what: int) -> void:
	# Save the game automatically when the player quits the application.
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()

##- Public API: Scores & Game Loop --------------------------------------------##

func get_high_score() -> int:
	return _high_score

func get_total_score() -> int:
	return _total_score

func get_current_score() -> int:
	return _current_game_score

func add_score_from_enemy(value: int) -> void:
	_current_game_score += value * _score_multiplier
	current_score_updated.emit(_current_game_score)

func add_score_from_boss(value: int) -> void:
	_current_game_score += value
	current_score_updated.emit(_current_game_score)

func set_score_multiplier(multiplier: int) -> void:
	var new_multiplier = max(1, multiplier)
	if _score_multiplier == new_multiplier:
		return
	_score_multiplier = new_multiplier
	score_multiplier_changed.emit(_score_multiplier)

# Called at the start of a new game from the main scene.
func reset_current_score() -> void:
	_current_game_score = 0

# Called at the end of a game round.
func finalize_run() -> void:
	_total_score += _current_game_score
	if _current_game_score > _high_score:
		_high_score = _current_game_score
	total_score_updated.emit(_total_score)
	save_game()

##- Public API: Equipment -----------------------------------------------------##

func get_equipped_ship_id() -> StringName:
	return _equipped_ship_id

func is_ship_owned(ship_id: StringName) -> bool:
	return ship_id in _owned_ship_ids

func purchase_ship(ship_id: StringName) -> bool:
	if is_ship_owned(ship_id): return false

	var ship_data: ShipData = EquipmentRegistry.get_ship_data(ship_id)
	if not ship_data: return false

	if _total_score >= ship_data.cost:
		_total_score -= ship_data.cost
		_owned_ship_ids.append(ship_id)
		total_score_updated.emit(_total_score)
		equip_ship(ship_id)
		return true
	return false
	
func equip_ship(ship_id: StringName) -> void:
	if not is_ship_owned(ship_id):
		return
	_equipped_ship_id = ship_id
	save_game()

##- Public API: Upgrades ------------------------------------------------------##
func get_upgrade_level(ship_id: StringName, upgrade_id: StringName) -> int:
	if not _upgrade_levels.has(ship_id): return 0
	return _upgrade_levels[ship_id].get(upgrade_id, 0)

func purchase_upgrade(ship_id: StringName, upgrade_id: StringName) -> bool:
	var upgrade_data: UpgradeData = UpgradeRegistry.get_upgrade_data(upgrade_id)
	if not upgrade_data: return false
	
	var current_level = get_upgrade_level(ship_id, upgrade_id)
	if current_level >= upgrade_data.max_level: return false
	
	var cost = upgrade_data.cost_per_level[current_level]
	if _total_score >= cost:
		_total_score -= cost
		
		if not _upgrade_levels.has(ship_id):
			_upgrade_levels[ship_id] = {}
			
		_upgrade_levels[ship_id][upgrade_id] = current_level + 1
		total_score_updated.emit(_total_score)
		save_game()
		return true
	return false

##- Public API: Settings & Saving ---------------------------------------------##

func get_settings() -> Dictionary:
	return _current_settings.duplicate(true)

func update_settings(new_settings: Dictionary) -> void:
	_current_settings = new_settings
	save_game()

func save_game() -> void:
	_save_data()

##- Private Save/Load Logic ---------------------------------------------------##

func _load_data() -> void:
	_current_settings = _DEFAULT_SETTINGS.duplicate(true)
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		save_game()
		return
	
	var file: FileAccess = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if not file: return
	
	var loaded_variant = file.get_var()
	file.close()
	
	if typeof(loaded_variant) != TYPE_DICTIONARY: return
	
	var loaded_data: Dictionary = loaded_variant
	
	# Load all persistent data, with fallbacks for safety.
	_high_score = loaded_data.get("high_score", 0)
	_total_score = loaded_data.get("total_score", 0)
	_upgrade_levels = loaded_data.get("upgrade_levels", {})
	_equipped_ship_id = loaded_data.get("equipped_ship_id", DEFAULT_SHIP_ID)
	
	var untyped_owned_ids: Array = loaded_data.get("owned_ship_ids", [DEFAULT_SHIP_ID])
	var typed_owned_ids: Array[StringName] = []
	for id in untyped_owned_ids:
		typed_owned_ids.append(StringName(id))
	_owned_ship_ids = typed_owned_ids

	var loaded_settings: Dictionary = loaded_data.get("settings", {})
	_current_settings.merge(loaded_settings, true)

func _save_data() -> void:
	var file: FileAccess = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if not file: return
	
	var data_to_save: Dictionary = {
		"high_score": _high_score,
		"total_score": _total_score,
		"settings": _current_settings,
		"upgrade_levels": _upgrade_levels,
		"owned_ship_ids": _owned_ship_ids,
		"equipped_ship_id": _equipped_ship_id
	}
	file.store_var(data_to_save)
	file.close()
