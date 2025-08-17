class_name ArmorShard
extends Area2D

##- Export Variables ----------------------------------------------------------##
@export var armor_shard_textures: Array[Texture]

@export var speed: float = 900.0
@export var damage: int = 1

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var timer: Timer = $Timer

##- Private Variables ---------------------------------------------------------##
var _direction: Vector2 = Vector2.ZERO

##- Godot Engine Functions ----------------------------------------------------##
func _process(delta: float) -> void:
	position += _direction * speed * delta
	sprite_2d.rotation += delta

##- Public Functions ----------------------------------------------------------##
func setup(new_direction: Vector2) -> void:
	sprite_2d.texture = armor_shard_textures.pick_random()
	_direction = new_direction.normalized()

##- Signal Handlers -----------------------------------------------------------##
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") and !body._is_dead:
		if body.has_method("take_damage"):
			body.take_damage(damage)
			timer.stop()
			queue_free()

func _on_timer_timeout() -> void:
	queue_free()
