class_name Payload
extends CharacterBody2D

##- Signals -------------------------------------------------------------------##
signal destroyed
signal health_changed(current: int, max: int)
signal took_damage

const STOP_THRESHOLD = 5.0
const HORIZONTAL_THRESHOLD = 0.7

##- Public State -------------------------------------------------------------##
@export_group("Stats")
@export var max_health: int = 10
@export var health: int

@export_group("Movement")
@export var follow_distance: float = 160.0
@export var acceleration: float = 2.5
@export var rotation_speed: float = 4.0

##- Private State -------------------------------------------------------------##
var _target_node: Node2D = null
var _target_rotation: float = 0.0
var _is_invincible: bool = false
var _is_dead: bool = false

##- Node References -----------------------------------------------------------##
@onready var explosion_anim: AnimatedSprite2D = $ExplosionAnim
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var damage_timer: Timer = $DamageTimer
@onready var hit_sound: AudioStreamPlayer = $HitSound

##- Godot Engine Functions ----------------------------------------------------##
func _ready() -> void:
	health = max_health
	health_changed.emit(health, max_health)

func _physics_process(delta: float) -> void:
	if _is_dead:
		set_physics_process(false)
		return

	if not is_instance_valid(_target_node):
		velocity = velocity.lerp(Vector2.ZERO, delta * acceleration)
		move_and_slide()
		return

	var target_position = _target_node.global_position + Vector2(0, follow_distance)
	
	var direction = global_position.direction_to(target_position)
	var distance = global_position.distance_to(target_position)
	
	var target_velocity = direction * distance * acceleration

	velocity = velocity.lerp(target_velocity, delta * acceleration)
	move_and_slide()
	_handle_animation(target_velocity)
	
	if velocity.length() > 1.0:
		rotation_degrees = lerp(rotation_degrees, _target_rotation, rotation_speed * delta)


func _handle_animation(current_velocity: Vector2) -> void:
	if _is_invincible:
		animated_sprite.play("damaged")
		return

	if current_velocity.length() < STOP_THRESHOLD:
		animated_sprite.play("up")
		_target_rotation = 0
		return
	var dir = current_velocity.normalized()
	
	if abs(dir.x) > HORIZONTAL_THRESHOLD:
		if dir.x < 0:
			_target_rotation = -20
		else:
			_target_rotation = 20
	else:
		_target_rotation = 0
	
	if not _is_invincible:
		if dir.y > 0.5:
			animated_sprite.play("down")
		else:
			animated_sprite.play("up")

##- Public API ----------------------------------------------------------------##
func set_follow_target(target: Node2D) -> void:
	_target_node = target

func take_damage(amount: int) -> void:
	if health <= 0 or _is_invincible: return
	_is_invincible = true
	health = max(0, health - amount)
	health_changed.emit(health, max_health)
	took_damage.emit()
	hit_sound.play()
	animated_sprite.play("damaged")
	damage_timer.start()
	
	if health == 0:
		_is_dead = true
		animated_sprite.visible = false
		explosion_anim.visible = true
		explosion_anim.play("Boom")

func add_health(amount: int) -> void:
	if health <= 0: return
	
	health = min(max_health, health + amount)
	health_changed.emit(health, max_health)

##- Signal Handlers -----------------------------------------------------------##
func _on_explosion_anim_animation_finished() -> void:
	destroyed.emit()
	queue_free()

func _on_damage_timer_timeout() -> void:
	_is_invincible = false
