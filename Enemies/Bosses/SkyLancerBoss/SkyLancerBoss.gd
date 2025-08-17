class_name SkyLancerBoss
extends CharacterBody2D

##- Signals -------------------------------------------------------------------##
signal boss_defeated
signal health_changed(health: int)

##- State Machine Enum --------------------------------------------------------##
enum State { SPAWNING, IDLE, PREPARE_ATTACK, DASHING, RECOIL, BACK, DEAD }

##- Export Variables ----------------------------------------------------------##
@export_group("Stats")
@export var speed: float = 900.0

@export_group("Movement")
@export var acceleration: float = 8.0
@export var stop_distance: float = 15.0
@export var recoil_distance: float = 250.0

@export_group("Timing")
@export var attack_cycle_duration: Vector2 = Vector2(10, 15)
@export var time_between_dashes: Vector2 = Vector2(1, 2)

##- Private Variables ---------------------------------------------------------##
var health: int = 300
var _is_dead: bool = false
var current_state: State = State.SPAWNING
var target_position: Vector2
var initial_position: Vector2 = Vector2(540, 500)

var character_node: CharacterBody2D

##- Node References -----------------------------------------------------------##
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var eye_marker: Marker2D = $BodySprite/Marker2D
@onready var attack_cycle_timer: Timer = $AttackCycleTimer
@onready var action_timer: Timer = $ActionTimer
@onready var damage_area: Area2D = $BossDamageArea
@onready var body_sprite: Node2D = $BodySprite
@onready var explosion_anim: AnimatedSprite2D = $ExplosionAnim
@onready var dash_sound: AudioStreamPlayer = $DashSound
@onready var explosion_sound: AudioStreamPlayer = $ExplosionSound
@onready var boss_damage_area_collision: CollisionShape2D = $BossDamageArea/CollisionShape2D
@onready var boss_collision: CollisionShape2D = $CollisionShape2D

##- The Contract Implementation -----------------------------------------------##

func setup(dependencies: Dictionary) -> void:
	if dependencies.has("character"):
		character_node = dependencies["character"]

func set_initial_health(amount: int) -> void:
	health = amount
	health_changed.emit(health)

func start() -> void:
	animation_player.play("ShowSelf")

##- Godot Engine Functions ----------------------------------------------------##
func _physics_process(delta: float) -> void:
	match current_state:
		State.IDLE:
			velocity = velocity.lerp(Vector2.ZERO, acceleration * delta)
		State.DASHING, State.RECOIL, State.BACK:
			var current_speed: float = speed * (1.5 if current_state == State.RECOIL else 1.0)
			var direction: Vector2 = global_position.direction_to(target_position)
			velocity = velocity.lerp(direction * current_speed, acceleration * delta)
			
			if global_position.distance_to(target_position) < stop_distance:
				if current_state == State.BACK:
					change_state(State.IDLE)
					var random_wait: int = randi() % 3 + 3 # randi_range(3, 5)
					action_timer.start(random_wait)
				else:
					change_state(State.IDLE)
	
	move_and_slide()
	
	if is_instance_valid(character_node):
		eye_marker.look_at(character_node.global_position)
	
	var collision = get_last_slide_collision()
	if collision and collision.get_collider() == character_node and current_state == State.DASHING:
		var recoil_direction: Vector2 = collision.get_normal().rotated(randf_range(-0.5, 0.5))
		target_position = global_position + recoil_direction * recoil_distance
		change_state(State.RECOIL)

##- State Machine Logic -------------------------------------------------------##

func change_state(new_state: State) -> void:
	if current_state == new_state or current_state == State.DEAD:
		return
		
	current_state = new_state

	match new_state:
		State.IDLE:
			if not attack_cycle_timer.is_stopped():
				action_timer.start(randf_range(time_between_dashes.x, time_between_dashes.y))
		
		State.PREPARE_ATTACK:
			if is_instance_valid(character_node):
				target_position = character_node.global_position
				animation_player.play("preFallowAnim")
			else:
				change_state(State.IDLE)
		
		State.DASHING:
			_play_dash_sound()
		
		State.BACK:
			_play_dash_sound(0.7, 1.0)
			target_position = initial_position
			animation_player.play("Back")

		State.DEAD:
			_is_dead = true
			attack_cycle_timer.stop()
			action_timer.stop()
			boss_collision.set_deferred("disabled", true)
			boss_damage_area_collision.set_deferred("disabled", true)
			damage_area.set_deferred("monitorable", false)
			damage_area.set_deferred("monitoring", false)
			body_sprite.visible = false
			explosion_anim.visible = true
			explosion_sound.play()
			explosion_anim.play("destroyed")
			boss_defeated.emit()
			set_physics_process(false)

##- Public & Private Functions ------------------------------------------------##
func take_damage(amount: int) -> void:
	if _is_dead:
		return
	health = max(0, health - amount)
	health_changed.emit(health)
	if health == 0:
		change_state(State.DEAD)

func _play_dash_sound(min_pitch: float = 0.8, max_pitch: float = 1.2) -> void:
	dash_sound.pitch_scale = randf_range(min_pitch, max_pitch)
	dash_sound.play(0.2)

##- Signal Handlers -----------------------------------------------------------##
func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	match anim_name:
		"ShowSelf":
			change_state(State.IDLE)
			var random_wait: int = randi() % 2 + 2 # Modern equivalent of randi_range(2, 3)
			action_timer.start(random_wait)
		"preFallowAnim":
			change_state(State.DASHING)

func _on_action_timer_timeout() -> void:
	if current_state != State.IDLE:
		return
	if attack_cycle_timer.is_stopped():
		attack_cycle_timer.start(randf_range(attack_cycle_duration.x, attack_cycle_duration.y))
		change_state(State.PREPARE_ATTACK)
	else:
		if is_instance_valid(character_node):
			target_position = character_node.global_position
			change_state(State.DASHING)
		else:
			change_state(State.IDLE)

func _on_attack_cycle_timer_timeout() -> void:
	if current_state != State.DEAD:
		change_state(State.BACK)

func _on_explosion_anim_animation_finished() -> void:
	queue_free()
