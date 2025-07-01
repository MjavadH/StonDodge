class_name Boss3Bullet
extends Area2D

##- Export Variables ----------------------------------------------------------##
@export var speed: float = 900.0
@export var damage: int = 1

##- Private Variables ---------------------------------------------------------##
var _direction: Vector2 = Vector2.ZERO

##- Godot Engine Functions ----------------------------------------------------##
func _process(delta: float) -> void:
	position += _direction * speed * delta

##- Public Functions ----------------------------------------------------------##
func set_direction(new_direction: Vector2) -> void:
	_direction = new_direction.normalized()

##- Signal Handlers -----------------------------------------------------------##
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") and !body._is_dead:
		if body.has_method("take_damage"):
			body.take_damage(damage)
			queue_free()

func _on_timer_timeout() -> void:
	queue_free()
