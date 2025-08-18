class_name RunicBomb
extends Area2D

@export var damage: int = 10

var _is_armed: bool = true

@onready var trigger_collision_shape: CollisionShape2D = $CollisionShape2D
@onready var explosion_radius: Area2D = $ExplosionRadius
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var explosion_sound: AudioStreamPlayer = $ExplosionSound
@onready var deploy_sound: AudioStreamPlayer = $DeploySound

func _ready() -> void:
	deploy_sound.play()

func _on_enemy_detected(entity: Node2D) -> void:
	if _is_armed and entity.is_in_group("Enemy"):
		explode()

func explode() -> void:
	_is_armed = false
	trigger_collision_shape.set_deferred("disabled", true)
	
	animated_sprite_2d.visible = true
	sprite_2d.visible = false
	animated_sprite_2d.play("explode")
	explosion_sound.play()
	
	# Find all enemies within the larger explosion radius.
	var targets = explosion_radius.get_overlapping_bodies() + explosion_radius.get_overlapping_areas()
	
	for target in targets:
		if target.is_in_group("Enemy") and target.has_method("take_damage"):
			target.take_damage(damage)

	# Wait for the explosion animation to finish, then remove the bomb from the game.
	await animated_sprite_2d.animation_finished
	queue_free()
