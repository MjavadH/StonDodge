extends Node2D

const METEOR_SCENE: PackedScene = preload("res://Enemies/Meteor/meteor.tscn")
const BONUS_SCENE: PackedScene = preload("res://Bonus/bonus.tscn")
const MINIDRONE_SCENE: PackedScene = preload("res://World/Mini-Drone/Mini-Drone.tscn")
const BOSS_WAVE_SEQUENCE: Array[StringName] = [&"CrimsonLord", &"Geode", &"SkyLancer", &"Prism",&"Vortex"]
const PAYLOAD_SCENE: PackedScene = preload("res://World/Payload/Payload.tscn")

##- Node References -----------------------------------------------------------##
@onready var top_path: Path2D = $TopPath
@onready var top_spawner: PathFollow2D = $TopPath/TopSpawner
@onready var spawn_timer: Timer = $SpawnTimer
@onready var bonus_timer: Timer = $bonusTimer
@onready var boss_timer: Timer = $bossTimer
@onready var camera_2d: Camera2D = $Camera2D
@onready var pause_menu: CanvasLayer = $Pause
@onready var in_game_hud: InGameHUD = $InGameHUD
@onready var blackout_overlay: BlackoutOverlay = $EffectsLayer/BlackoutOverlay
@onready var background_scene: Background = $Background

# Containers for spawned objects
@onready var meteors_container: Node = $Meteors
@onready var bullets_container: Node = $Bullets
@onready var bonus_container: Node = $Bonus
@onready var boss_container: Node2D = $BossContainer
@onready var abilities_container: Node = $Abilities
@onready var players: Node = $Players

##- Private Variables ---------------------------------------------------------##
var _boss_wave: int = 4
var _player_instance: BaseShip 
var _payload_instance: Payload = null
var _minidrone_instance: MiniDrone = null
##- Godot Engine Functions ----------------------------------------------------##
func _ready() -> void:
	# Handle the Android back button behavior.
	get_tree().get_root().connect("go_back_requested", _on_go_back_requested)
	in_game_hud.pause_request.connect(_on_go_back_requested)
	BossManager.boss_defeated.connect(_on_boss_manager_defeated)
	var screen_rect: Rect2 = get_viewport().get_visible_rect()
	
	GameManager.reset_current_score()
	_setup_offscreen_nodes(screen_rect)
	_resize_enemy_path(screen_rect)
	_spawn_player_ship(screen_rect)
	_configure_for_game_mode()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game"):
		pause_menu._pauseGame()

##- Public Functions ----------------------------------------------------------##
func spawn_meteor(is_bonus: bool = false) -> void:
	var meteor_data: MeteorData
	top_spawner.progress_ratio = randf()
	if is_bonus:
		meteor_data = MeteorRegistry.get_random_bonus_meteor()
	else:
		meteor_data = MeteorRegistry.get_random_regular_meteor()
		
	if not meteor_data: return # No meteor data found
	
	var meteor_instance: Meteor = METEOR_SCENE.instantiate()
	
	meteor_instance.global_position = top_spawner.global_position
	meteors_container.add_child(meteor_instance)
	meteor_instance.initialize(meteor_data)
	
	meteor_instance.bonus_dropped.connect(spawn_bonus)

func spawn_bonus(location: Vector2) -> void:
	if not is_instance_valid(_player_instance):
		return

	var ship_data: ShipData = EquipmentRegistry.get_ship_data(_player_instance.id)
	var bonus_data: BonusData
	
	if ship_data.compatible_bonuses.is_empty():
		bonus_data = BonusRegistry.get_random_weighted_bonus()
	else:
		bonus_data = BonusRegistry.get_random_weighted_bonus_from_dict(ship_data.compatible_bonuses)
	
	var bonus_instance: Bonus = BONUS_SCENE.instantiate()
	bonus_container.add_child(bonus_instance)
	bonus_instance.global_position = location
	bonus_instance.initialize(bonus_data)
	
	bonus_instance.collected.connect(_on_bonus_collected)

##- Private Functions ---------------------------------------------------------##

func _configure_for_game_mode() -> void:
	var mode = GameManager.get_game_mode()
	
	match mode:
		GameManager.GameMode.CLASSIC:
			spawn_timer.start()
			bonus_timer.start()
			boss_timer.start()
			
		GameManager.GameMode.SURVIVAL:
			spawn_timer.wait_time = 0.4
			spawn_timer.start()
			bonus_timer.start()
			boss_timer.stop()
			
		GameManager.GameMode.BOSS_RUSH:
			spawn_timer.stop()
			bonus_timer.stop()
			boss_timer.stop()
			_trigger_next_boss_encounter()
		GameManager.GameMode.BLACKOUT:
			spawn_timer.start()
			bonus_timer.start()
			boss_timer.start()
			blackout_overlay.show()
			blackout_overlay.add_light_source(_player_instance, 0.15)
			GameManager.set_score_multiplier(2)
		GameManager.GameMode.PAYLOAD_ESCORT:
			_start_payload_mode()

func _spawn_player_ship(screen_rect: Rect2) -> void:
	var ship_id = GameManager.get_equipped_ship_id()
	var ship_data: ShipData = EquipmentRegistry.get_ship_data(ship_id)
	
	if not ship_data:
		return
	_player_instance = ship_data.ship_scene.instantiate()
	
	var dependencies: Dictionary = {
		"bullet_container": bullets_container,
		"ship_id": ship_id,
		"top_spawner": top_spawner,
		"abilities_container": abilities_container
	}
	
	players.add_child(_player_instance)
	_player_instance.position = Vector2(screen_rect.get_center().x, screen_rect.size.y - 200)
	_player_instance.initialize(dependencies)
	
	pause_menu.character_node = _player_instance
	in_game_hud.track_player(_player_instance)
	
	_player_instance.died.connect(_on_player_died)
	_player_instance.took_damage.connect(_on_player_took_damage)
	_player_instance.request_drone.connect(_on_player_request_drone)

func _start_payload_mode():
	_payload_instance = PAYLOAD_SCENE.instantiate()
	_payload_instance.global_position = _player_instance.global_position + Vector2(0, _payload_instance.follow_distance)
	add_child(_payload_instance)
	in_game_hud.track_payload(_payload_instance)
	
	_payload_instance.set_follow_target(_player_instance)
	_payload_instance.destroyed.connect(_on_payload_destroyed)
	_payload_instance.took_damage.connect(_on_player_took_damage)
	
	spawn_timer.start()
	bonus_timer.start()
	boss_timer.start()
	GameManager.set_score_multiplier(2)

# clear all children from a node.
func _clear_container(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()

func _setup_offscreen_nodes(screen_rect: Rect2) -> void:
	# Nodes positioned just outside the viewport for smooth entry.
	top_path.position.y = -60.0
	($FreeZoneBottom as Area2D).position.y = screen_rect.size.y + 200.0
	($FreeZoneTop as Area2D).position.y = -200.0

func _resize_enemy_path(screen_rect: Rect2) -> void:
	var path_curve: Curve2D = top_path.curve
	var point_y: float = path_curve.get_point_position(0).y
	path_curve.set_point_position(0, Vector2(0, point_y))
	path_curve.set_point_position(1, Vector2(screen_rect.size.x, point_y))
	
##- Boss Trigger Logic --------------------------------------------------------##
func _trigger_next_boss_encounter() -> void:
	# Check if there are more bosses in the sequence.
	if _boss_wave >= BOSS_WAVE_SEQUENCE.size():
		return
	
	# Stop regular enemy spawns to focus on the boss.
	spawn_timer.stop()
	
	var boss_id_to_spawn: StringName = BOSS_WAVE_SEQUENCE[_boss_wave]
	
	# Prepare the package of dependencies that the boss might need.
	var dependencies: Dictionary = {
		"parent_node": boss_container,
		"character": _player_instance,
		"enemy_container": meteors_container,
		"bullet_container": bullets_container,
		"camera": camera_2d
	}
	
	# Call the global BossManager to start the encounter.
	var success: bool = BossManager.trigger_encounter(boss_id_to_spawn, dependencies)
	if success:
		_boss_wave += 1
		MusicPlayer.change_music(MusicPlayer.MusicType.BOSS)
		if GameManager.get_game_mode() == GameManager.GameMode.BLACKOUT:
			blackout_overlay.add_light_source(boss_container.get_child(0), 0.3)
		
	else:
		# If spawning failed, resume normal activity.
		spawn_timer.start()

##- Signal Handlers -----------------------------------------------------------##
func _on_go_back_requested() -> void:
	if not pause_menu.visible:
		pause_menu._pauseGame()

func _on_spawn_timer_timeout() -> void:
	spawn_meteor()

func _on_bonus_timer_timeout() -> void:
	spawn_meteor(true)
	# Increase difficulty by reducing spawn time.
	if spawn_timer.wait_time >= 0.4 and not spawn_timer.is_stopped():
		spawn_timer.wait_time -= 0.1

func _on_bonus_collected(bonus_type: StringName) -> void:
	# Safely apply the bonus to the current player instance.
	if is_instance_valid(_player_instance):
		_player_instance.apply_bonus(bonus_type)

func _on_boss_timer_timeout() -> void:
	_trigger_next_boss_encounter()

func _on_boss_manager_defeated(_boss_id: StringName, score_value: int) -> void:
	GameManager.add_score_from_boss(score_value)
	if GameManager.get_game_mode() == GameManager.GameMode.BOSS_RUSH:
		if _boss_wave >= BOSS_WAVE_SEQUENCE.size():
			_boss_wave = 0 # Loop back to the beginning.
		call_deferred("_trigger_next_boss_encounter")
	else:
		spawn_timer.start()
		boss_timer.start(boss_timer.wait_time + 20.0)
		MusicPlayer.change_music(MusicPlayer.MusicType.BACKGROUND)
		blackout_overlay.remove_light_source(boss_container.get_child(0))

func _on_player_died() -> void:
	background_scene.flash_drop_color()
	
	spawn_timer.stop()
	bonus_timer.stop()
	boss_timer.stop()
	
	_clear_container(meteors_container)
	_clear_container(bullets_container)
	_clear_container(bonus_container)
	
	get_tree().change_scene_to_file("res://UI/GameOver/GameOverScreen.tscn")

func _on_player_took_damage() -> void:
	# Visual feedback for player damage.
	background_scene.flash_drop_color(Color.RED)
	camera_2d.start_shake()
	await get_tree().create_timer(1.2).timeout
	
	background_scene.flash_drop_color()

func _on_player_request_drone() -> void:
	if _minidrone_instance == null:
		_minidrone_instance = MINIDRONE_SCENE.instantiate()
		var viewport_rect: Vector2 = get_viewport_rect().size
		_minidrone_instance.global_position = Vector2(viewport_rect.x /2,viewport_rect.y + 100)
		bonus_container.call_deferred("add_child",_minidrone_instance)
		_minidrone_instance.set_follow_target(_player_instance)

func _on_payload_destroyed():
	GameManager.set_score_multiplier(1)
	_on_player_died()
