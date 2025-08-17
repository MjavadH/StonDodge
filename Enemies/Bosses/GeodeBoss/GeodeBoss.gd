class_name GeodeBoss
extends CharacterBody2D

const LASER_SCENE = preload("res://Enemies/Bosses/GeodeBoss/PathLaser.tscn")

##- Signals -------------------------------------------------------------------##
signal boss_defeated
signal health_changed(health: int)

##- Export Variables ----------------------------------------------------------##
@export_group("Attacks")
@export var laser_animation_reveal_duration: float = 1.5
@export var laser_animation_hold_duration: float = 1.5
@export var laser_animation_retract_duration: float = 0.3

##- State Machine -------------------------------------------------------------##
enum State { SPAWNING, PHASE_ONE, TRANSITIONING, PHASE_TWO, DEAD }
var current_state: State = State.SPAWNING

##- Private Variables ---------------------------------------------------------##

var health: int = 400
var _armor_health: int = 200
var _core_health: int = 200
var _is_dead: bool = false
var _projectile_scene: PackedScene
var _rotation_speed_phase1: float = 1.0
var _rotation_speed_phase2: float = 3.0
var _laser_bounces: int = 4

##- Dependencies --------------------------------------------------------------##
var _character_node: CharacterBody2D
var _bullet_container: Node

##- Node References -----------------------------------------------------------##

@onready var explosion_anim: AnimatedSprite2D = $ExplosionAnim
@onready var explosion_sound: AudioStreamPlayer = $ExplosionSound
@onready var damage_area: Area2D = $BossDamageArea
@onready var boss_collision: CollisionShape2D = $CollisionShape2D
@onready var boss_damage_area_collision: CollisionShape2D = $BossDamageArea/CollisionShape2D
@onready var move_animation: AnimationPlayer = $MoveAnimation
@onready var shoot_cooldown: Timer = $ShootCooldown
@onready var body_node: Node2D = $BodySprite
@onready var leaser_shoot_sound: AudioStreamPlayer = $LeaserShootSound
@onready var attack_spawn_point: Marker2D = $Marker2D/AttackSpawnPoint
@onready var leaser_container: Node = $LeaserContainer
@onready var rock_shoot_sound: AudioStreamPlayer = $RockShootSound
@onready var transitioning_sound: AudioStreamPlayer = $TransitioningSound
@onready var transition_sound: AudioStreamPlayer = $TransitionSound

##- The Contract Implementation -----------------------------------------------##
func setup(dependencies: Dictionary) -> void:
	if dependencies.has("character"):
		_character_node = dependencies["character"]
	if dependencies.has("bullet_container"):
		_bullet_container = dependencies["bullet_container"]
	if dependencies.has("projectile_scene"):
		_projectile_scene = dependencies["projectile_scene"]

func set_initial_health(amount: int) -> void:
	health = amount
	var half_health: float = float(health) / 2.0
	_armor_health = int(ceil(half_health))
	_core_health = int(floor(half_health))
	health_changed.emit(health)

func start() -> void:
	move_animation.play("ShowSelf")
	change_state(State.PHASE_ONE)

##- Godot Engine Functions ----------------------------------------------------##
func _physics_process(delta: float) -> void:
	if _is_dead or not is_instance_valid(_character_node) or current_state == State.TRANSITIONING: return

	var target_angle = global_position.direction_to(_character_node.global_position).angle()
	var current_rotation_speed = _rotation_speed_phase1
	if current_state == State.PHASE_TWO:
		current_rotation_speed = _rotation_speed_phase2

	global_rotation = lerp_angle(global_rotation, target_angle, delta * current_rotation_speed)

##- Core Logic ----------------------------------------------------------------##

func take_damage(amount: int) -> void:
	if _is_dead: return

	match current_state:
		State.PHASE_ONE:
			_armor_health = max(0, _armor_health - amount)
			if _armor_health == 0:
				change_state(State.TRANSITIONING)
		
		State.PHASE_TWO:
			_core_health = max(0, _core_health - amount)
			if _core_health == 0:
				die()
	
	health = _armor_health + _core_health
	health_changed.emit(health)

func change_state(new_state: State):
	if current_state == new_state: return
	current_state = new_state

	match new_state:
		State.PHASE_ONE:
			shoot_cooldown.start(randf_range(3.0, 5.0))

		State.TRANSITIONING:
			shoot_cooldown.stop()
			explosion_anim.visible = true
			var animation = move_animation.get_animation("Transitioning")
			animation.track_set_key_value(0, 0, self.global_position)
			animation.track_set_key_value(0, 1, self.global_position)
			move_animation.stop(true)
			explosion_anim.play("Phase1explosion1")
			transitioning_sound.play()

		State.PHASE_TWO:
			shoot_cooldown.start(randf_range(1.5, 3.0))

func die() -> void:
	if _is_dead:
		return
	_is_dead = true
	
	boss_defeated.emit()
	explosion_sound.play()
	
	boss_collision.set_deferred("disabled", true)
	boss_damage_area_collision.set_deferred("disabled", true)
	damage_area.monitorable = false
	damage_area.monitoring = false
	
	body_node.visible = false
	explosion_anim.visible = true
	explosion_anim.play("destroyed")
	
##- Attack Functions ----------------------------------------------------------##

func _shoot_armor_shard():
	var projectile = _projectile_scene.instantiate()
	
	_bullet_container.add_child(projectile)
	projectile.global_position = attack_spawn_point.global_position
	
	# Aim at player
	var direction = (_character_node.global_position - projectile.global_position).normalized()
	if projectile.has_method("setup"):
		projectile.setup(direction)

func _attack_area_denial_laser():
	if not is_instance_valid(_character_node): return

	var laser: PathLaser = LASER_SCENE.instantiate()
	leaser_container.add_child(laser)
	var point_one = attack_spawn_point.global_position + Vector2(0,-50)
	var path_points = [point_one]
	var current_point = point_one
	var player_pos = _character_node.global_position
	
	_laser_bounces = randi() % 6 + 2
	for i in _laser_bounces:
		var predicted_player_pos = player_pos + _character_node.velocity * 0.2
		var target_x = randf_range(predicted_player_pos.x - 300.0, predicted_player_pos.x + 300.0)
		var target_y = randf_range(predicted_player_pos.y - 300.0, predicted_player_pos.y + 300.0)
		var target_point = Vector2(target_x, target_y)
		
		var next_point = current_point.lerp(target_point, randf_range(0.8, 1.2))
		next_point = bounce(next_point)

		path_points.append(next_point)
		current_point = next_point

	laser.fire(path_points, laser_animation_reveal_duration, laser_animation_hold_duration, laser_animation_retract_duration)

func _attack_random_point_laser():
	var laser: PathLaser = LASER_SCENE.instantiate()
	leaser_container.add_child(laser)
	var point_one = attack_spawn_point.global_position + Vector2(0,-50)
	var path_points = [point_one]
	var current_point = point_one
	# Second Point
	var player_pos = _character_node.global_position
	var predicted_player_pos = player_pos + _character_node.velocity * 0.2
	var player_x = randf_range(predicted_player_pos.x - 300.0, predicted_player_pos.x + 300.0)
	var player_y = randf_range(predicted_player_pos.y - 300.0, predicted_player_pos.y + 300.0)
	var player_point = Vector2(player_x, player_y)
	var second_point = current_point.lerp(player_point, randf_range(0.8, 1.2))
	path_points.append(second_point)
	current_point = second_point
	
	# Next Point
	_laser_bounces = randi() % 5 + 3
	for i in _laser_bounces:
		var target_x = randf_range(current_point.x + 300.0, current_point.x - 300.0)
		var target_y = randf_range(current_point.y + 100.0, current_point.y - 100)
		var target_point = Vector2(target_x, target_y)
		
		var next_point = current_point.lerp(target_point, randf_range(0.8, 1.2))
		next_point = bounce(next_point)

		path_points.append(next_point)
		current_point = next_point

	laser.fire(path_points, laser_animation_reveal_duration, laser_animation_hold_duration, laser_animation_retract_duration)

func bounce(point: Vector2) -> Vector2:
	var viewport_rect = get_viewport_rect()
	point = point.clamp(Vector2.ZERO, viewport_rect.size)
	var bounce_offset = randf_range(100.0, 200.0)
	if point.x >= viewport_rect.size.x:
		point.x -= bounce_offset  * 1.5
	elif point.x <= 0.0:
		point.x += bounce_offset  * 1.5
	if point.y >= viewport_rect.size.y:
		point.y -= bounce_offset
	elif point.y <= 0.0:
		point.y += bounce_offset
	return point

##- Signal Handlers -----------------------------------------------------------##

func _on_explosion_anim_animation_finished() -> void:
	if explosion_anim.animation == "destroyed":
		queue_free()
	elif explosion_anim.animation == "Phase1explosion1":
		explosion_anim.play("Phase1explosion2")
		transition_sound.play()
		move_animation.play("Transitioning")
	elif explosion_anim.animation == "Phase1explosion2":
		explosion_anim.visible = false

func _on_shoot_cooldown_timeout() -> void:
	if _is_dead: return
	
	match current_state:
		State.PHASE_ONE:
			_shoot_armor_shard()
			rock_shoot_sound.play()
			shoot_cooldown.start(randf_range(2.0, 3.0))
		State.PHASE_TWO:
			for i in randi() % 7 + 3:
				match randi() % 2:
					0:
						_attack_area_denial_laser()
					1:
						_attack_random_point_laser()

			leaser_shoot_sound.play()
			var total_laser_time = laser_animation_reveal_duration + laser_animation_hold_duration + laser_animation_retract_duration
			shoot_cooldown.start(total_laser_time + randf_range(0.5, 1.5))
