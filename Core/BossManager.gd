# The BossManager (Autoload).
extends Node

##- Signals -------------------------------------------------------------------##
# Emitted when a boss is successfully defeated. The main game can listen to this
# to grant rewards, change music, resume normal spawns, etc.
signal boss_defeated(boss_id: StringName, score_value: int)

##- Export Variables ----------------------------------------------------------##
# This array holds all the boss. You create BossData resources
# in the editor and drag them here.
@export var boss_definitions: Array[BossData]

var _boss_data_map: Dictionary = {}
var _current_boss_instance: Node = null

##- Godot Engine Functions ----------------------------------------------------##
func _ready() -> void:
	for data in boss_definitions:
		if data and data.id != &"":
			_boss_data_map[data.id] = data
		else:
			printerr("BossManager: A BossData resource is invalid or has no ID.")

##- Public API ----------------------------------------------------------------##

# This is the main function to start a boss fight.
# The main game script calls this, e.g., BossManager.trigger_encounter(&"SwarmQueen")
func trigger_encounter(boss_id: StringName, dependencies: Dictionary) -> bool:
	if _current_boss_instance != null:
		printerr("BossManager: Cannot trigger a new encounter while a boss is active.")
		return false
		
	if not _boss_data_map.has(boss_id):
		printerr("BossManager: No boss found with ID: ", boss_id)
		return false

	var boss_data: BossData = _boss_data_map[boss_id]
	
	# --- Spawning and Configuration ---
	_current_boss_instance = boss_data.boss_scene.instantiate()
	
	if boss_data.projectile_scene:
		dependencies["projectile_scene"] = boss_data.projectile_scene
	
	if _current_boss_instance.has_method("setup"):
		_current_boss_instance.setup(dependencies)
	
	if _current_boss_instance.has_method("set_initial_health"):
		_current_boss_instance.set_initial_health(boss_data.initial_health)

	# Connect to the boss's 'defeated' signal to know when the fight is over.
	_current_boss_instance.boss_defeated.connect(
		func(): _on_boss_defeated(boss_data)
	)
	
	# Add the boss to the scene tree and start its logic.
	# The spawner (e.g., the Main scene) provides the parent node.
	var parent_node = dependencies.get("parent_node")
	if is_instance_valid(parent_node):
		parent_node.add_child(_current_boss_instance)
	else:
		get_tree().get_root().add_child(_current_boss_instance)
		
	if _current_boss_instance.has_method("start"):
		_current_boss_instance.start()
		
	return true

##- Signal Handlers -----------------------------------------------------------##
func _on_boss_defeated(boss_data: BossData) -> void:
	boss_defeated.emit(boss_data.id, boss_data.score_on_defeat)
	_current_boss_instance = null # Allow a new boss to be spawned.
