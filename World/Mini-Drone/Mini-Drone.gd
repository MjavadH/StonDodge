class_name MiniDrone
extends CharacterBody2D

const STOP_THRESHOLD = 5.0
const HORIZONTAL_THRESHOLD = 0.7

##- Public State -------------------------------------------------------------##

@export var projectile: PackedScene

@export_group("Movement")
@export var follow_distance: Vector2 = Vector2(-100,-50)
@export var acceleration: float = 3.5
@export var rotation_speed: float = 4.0

##- Private State -------------------------------------------------------------##
var _target_node: Node2D = null
var _target_rotation: float = 0.0

##- Node References -----------------------------------------------------------##
@onready var sprite: Sprite2D = $Sprite2D
@onready var explosion_anim: AnimatedSprite2D = $ExplosionAnim
@onready var shoot_sound: AudioStreamPlayer = $ShootSound
@onready var shoot_cooldown: Timer = $ShootCooldown
@onready var detection_radius: Area2D = $DetectionRadius
@onready var bullet_container: Node = $BulletContainer
@onready var bullet_spawn_point: Marker2D = $BulletSpawnPoint

##- Godot Engine Functions ----------------------------------------------------##

func _physics_process(delta: float) -> void:
	if not is_instance_valid(_target_node):
		velocity = velocity.lerp(Vector2.ZERO, delta * acceleration)
		move_and_slide()
		return

	var target_position = _target_node.global_position + follow_distance
	
	var direction = global_position.direction_to(target_position)
	var distance = global_position.distance_to(target_position)
	
	var target_velocity = direction * distance * acceleration

	velocity = velocity.lerp(target_velocity, delta * acceleration)
	move_and_slide()
	_handle_animation(target_velocity)
	
	if velocity.length() > 1.0:
		rotation_degrees = lerp(rotation_degrees, _target_rotation, rotation_speed * delta)


func _handle_animation(current_velocity: Vector2) -> void:
	var dir = current_velocity.normalized()
	
	if abs(dir.x) > HORIZONTAL_THRESHOLD:
		if dir.x < 0:
			_target_rotation = -20
		else:
			_target_rotation = 20
	else:
		_target_rotation = 0

##- Public & private API ----------------------------------------------------------------##
func set_follow_target(target: Node2D) -> void:
	_target_node = target

func Shoot() -> void:
	var nearest_target: Node2D = null
	var areas: Array[Area2D] = detection_radius.get_overlapping_areas()
	var bodies: Array[Node2D] = detection_radius.get_overlapping_bodies()
	
	if not bodies.is_empty():
		nearest_target = bodies[0]
	if not areas.is_empty():
		nearest_target = areas[0]
	
	if nearest_target:
		var bullet = projectile.instantiate()
		bullet_container.add_child(bullet)
		bullet.global_position = bullet_spawn_point.global_position
		
		var direction = global_position.direction_to(nearest_target.global_position)
		bullet.rotation = direction.angle()
		
		shoot_sound.play()


##- Signal Handlers -----------------------------------------------------------##
func _on_explosion_anim_animation_finished() -> void:
	queue_free()

func _on_destroy_timer_timeout() -> void:
	shoot_cooldown.stop()
	sprite.hide()
	explosion_anim.show()
	set_physics_process(false)
	explosion_anim.play("destroy")

func _on_shoot_cooldown_timeout() -> void:
	Shoot()
