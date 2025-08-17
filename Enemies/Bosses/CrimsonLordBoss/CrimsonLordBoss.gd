class_name CrimsonLordBoss
extends CharacterBody2D

##- Signals -------------------------------------------------------------------##
signal boss_defeated
signal health_changed(health: int)

##- Constants -----------------------------------------------------------------##
const METEOR_SCENE: PackedScene = preload("res://Enemies/Meteor/meteor.tscn")

##- Private Variables ---------------------------------------------------------##
var health: int = 100
var _is_dead: bool = false
var character_node: CharacterBody2D
var enemy_container: Node
var camera_node: Camera2D

##- Node References -----------------------------------------------------------##
@onready var body_sprite: Node2D = $BodySprite
@onready var eye_marker: Marker2D = $BodySprite/Marker2D
@onready var explosion_anim: AnimatedSprite2D = $ExplosionAnim
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var pulse_timer: Timer = $PulseTimer
@onready var meteor_spawner: PathFollow2D = $Path2D/PathFollow2D
@onready var damage_area: Area2D = $BossDamageArea
@onready var pulse_sound: AudioStreamPlayer = $PulseSound
@onready var explosion_sound: AudioStreamPlayer = $ExplosionSound
@onready var move_animation: AnimationPlayer = $MoveAnimation
@onready var boss_damage_area_collision: CollisionShape2D = $BossDamageArea/CollisionShape2D
@onready var boss_collision: CollisionShape2D = $CollisionShape2D

##- Godot Engine Functions ----------------------------------------------------##

func _physics_process(_delta: float) -> void:
	if is_instance_valid(character_node):
		eye_marker.look_at(character_node.global_position)

##- The Contract Implementation -----------------------------------------------##
func setup(dependencies: Dictionary) -> void:
	if dependencies.has("character"):
		character_node = dependencies["character"]
	if dependencies.has("enemy_container"):
		enemy_container = dependencies["enemy_container"]
	if dependencies.has("camera"):
		camera_node = dependencies["camera"]

func set_initial_health(amount: int) -> void:
	health = amount

func start() -> void:
	animation_player.play("ShowSelf")
	animation_player.animation_finished.connect(_on_intro_animation_finished, CONNECT_ONE_SHOT)

##- Public Functions ----------------------------------------------------------##
func take_damage(amount: int) -> void:
	if _is_dead:
		return
	health = max(0, health - amount)
	health_changed.emit(health)
	if health == 0:
		call_deferred("_die")

##- Private Functions ---------------------------------------------------------##
func _spawn_meteor(count: int = 1) -> void:
	var meteor_data: MeteorData
	meteor_data = MeteorRegistry.get_random_special_meteor()
	if not meteor_data: return
	for i in range(count):
		meteor_spawner.progress_ratio = randf()
		var meteor_instance: Meteor = METEOR_SCENE.instantiate()
		meteor_instance.global_position = meteor_spawner.global_position
		enemy_container.add_child(meteor_instance)
		meteor_instance.initialize(meteor_data)

func _die() -> void:
	if _is_dead:
		return
	
	_is_dead = true
	boss_defeated.emit()
	explosion_sound.play()
	
	boss_collision.set_deferred("disabled", true)
	boss_damage_area_collision.set_deferred("disabled", true)
	damage_area.set_deferred("monitorable", false)
	damage_area.set_deferred("monitoring", false)
	
	body_sprite.visible = false
	explosion_anim.visible = true
	explosion_anim.play("destroyed")

##- Signal Handlers -----------------------------------------------------------##
func _on_intro_animation_finished(anim_name: StringName) -> void:
	if anim_name == "ShowSelf":
		pulse_timer.start(randf_range(0.5, 2.0))
		move_animation.play("move")

func _on_pulse_timer_timeout() -> void:
	if _is_dead:
		return
	animation_player.speed_scale = randf_range(1.0, 2.0)
	animation_player.play("Pulse")

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Pulse" and not _is_dead:
		camera_node.start_shake(5)
		pulse_sound.pitch_scale = randf_range(0.8, 1.2)
		pulse_sound.play()
		var meteor_count: int = randi() % 4 + 1 # Random integer between 1 and 4
		_spawn_meteor(meteor_count)
		
		pulse_timer.start(randf_range(0.5, 2.0))

func _on_explosion_anim_animation_finished() -> void:
	queue_free()
