extends Node2D

const METEOR_SCENE: PackedScene = preload("res://Enemies/Meteor/meteor.tscn")
const BONUS_SCENE: PackedScene = preload("res://Bonus/bonus.tscn")
const BOSS_WAVE_SEQUENCE: Array[StringName] = [&"Boss1", &"Boss2", &"Boss3"]

##- Node References -----------------------------------------------------------##
@onready var enemy_path: Path2D = $EnemyPath
@onready var enemy_spawner: PathFollow2D = $EnemyPath/EnemySpawner
@onready var spawn_timer: Timer = $SpawnTimer
@onready var bonus_timer: Timer = $bonusTimer
@onready var boss_timer: Timer = $bossTimer
@onready var camera_2d: Camera2D = $Camera2D
@onready var pause_menu: CanvasLayer = $Pause
@onready var in_game_hud: CanvasLayer = $InGameHUD

# Containers for spawned objects
@onready var meteors_container: Node = $Meteors
@onready var bullets_container: Node = $Bullets
@onready var bonus_container: Node = $Bonus
@onready var boss_container: Node2D = $BossContainer

@onready var background_shader: ShaderMaterial = $CanvasLayer/background.material

##- Private Variables ---------------------------------------------------------##
var _boss_wave: int = 0
var _player_instance: BaseShip 

##- Godot Engine Functions ----------------------------------------------------##
func _ready() -> void:
	# Handle the Android back button behavior.
	get_tree().get_root().connect("go_back_requested", _on_go_back_requested)
	BossManager.boss_defeated.connect(_on_boss_manager_defeated)
	var screen_rect: Rect2 = get_viewport().get_visible_rect()
	
	GameManager.reset_current_score()
	_setup_offscreen_nodes(screen_rect)
	_configure_background_shader()
	_resize_enemy_path(screen_rect)
	_spawn_player_ship(screen_rect)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game"):
		pause_menu._pauseGame()

##- Public Functions ----------------------------------------------------------##
func spawn_meteor(is_bonus: bool = false):
	var meteor_data: MeteorData
	enemy_spawner.progress_ratio = randf()
	if is_bonus:
		meteor_data = MeteorRegistry.get_random_bonus_meteor()
	else:
		meteor_data = MeteorRegistry.get_random_regular_meteor()
		
	if not meteor_data: return # No meteor data found
	
	var meteor_instance: Meteor = METEOR_SCENE.instantiate()
	
	meteor_instance.global_position = enemy_spawner.global_position
	meteors_container.add_child(meteor_instance)
	meteor_instance.initialize(meteor_data)
	
	meteor_instance.bonus_dropped.connect(spawn_bonus)

func spawn_bonus(location: Vector2) -> void:
	var bonus_instance: Node2D = BONUS_SCENE.instantiate()
	var bonus_type: Dictionary = bonus_instance.bonus_types.pick_random()
	
	bonus_instance.setup(bonus_type)
	bonus_instance.global_position = location
	bonus_container.add_child(bonus_instance)

##- Private Functions ---------------------------------------------------------##

func _spawn_player_ship(screen_rect: Rect2) -> void:
	var ship_id = GameManager.get_equipped_ship_id()
	var ship_data: ShipData = EquipmentRegistry.get_ship_data(ship_id)
	
	if not ship_data:
		return
	_player_instance = ship_data.ship_scene.instantiate()
	
	var dependencies = {
		"bullet_container": bullets_container,
		"ship_id": ship_id
	}
	
	add_child(_player_instance)
	_player_instance.position = Vector2(screen_rect.get_center().x, screen_rect.size.y - 200)
	_player_instance.initialize(dependencies)
	
	pause_menu.character_node = _player_instance
	in_game_hud.track_player(_player_instance)
	
	_player_instance.died.connect(_on_player_died)
	_player_instance.took_damage.connect(_on_player_took_damage)

# clear all children from a node.
func _clear_container(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()

func _setup_offscreen_nodes(screen_rect: Rect2) -> void:
	# Nodes positioned just outside the viewport for smooth entry.
	enemy_path.position.y = -60.0
	($FreeZoneBottom as Area2D).position.y = screen_rect.size.y + 200.0
	($FreeZoneTop as Area2D).position.y = -200.0

func _configure_background_shader() -> void:
	var main_color: Vector3 = Vector3(1.0, 1.0, 1.0)
	var bg_color: Vector3 = Vector3(0.0, 0.0, 0.0)

	background_shader.set_shader_parameter("color", main_color)
	background_shader.set_shader_parameter("background_color", bg_color)

func _resize_enemy_path(screen_rect: Rect2) -> void:
	var path_curve: Curve2D = enemy_path.curve
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
	
	var boss_id_to_spawn = BOSS_WAVE_SEQUENCE[_boss_wave]
	
	# Prepare the package of dependencies that the boss might need.
	var dependencies = {
		"parent_node": boss_container,
		"character": _player_instance,
		"enemy_container": meteors_container,
		"bullet_container": bullets_container,
		"camera": camera_2d
	}
	
	# Call the global BossManager to start the encounter.
	var success = BossManager.trigger_encounter(boss_id_to_spawn, dependencies)
	if success:
		_boss_wave += 1
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

func _on_boss_timer_timeout() -> void:
	_trigger_next_boss_encounter()

func _on_boss_manager_defeated(_boss_id: StringName, score_value: int) -> void:
	GameManager.add_score_from_boss(score_value)
	spawn_timer.start()
	boss_timer.start(boss_timer.wait_time + 20.0)

func _on_player_died() -> void:
	spawn_timer.stop()
	bonus_timer.stop()
	boss_timer.stop()
	
	_clear_container(meteors_container)
	_clear_container(bullets_container)
	_clear_container(bonus_container)
	
	get_tree().change_scene_to_file("res://UI/GameOver/GameOverScreen.tscn")

func _on_player_took_damage() -> void:
	# Visual feedback for player damage.
	background_shader.set_shader_parameter("color", Color.RED)
	camera_2d.start_shake()
	
	await get_tree().create_timer(1.2).timeout
	
	# Restore the original color by re-running the setup logic.
	_configure_background_shader()
