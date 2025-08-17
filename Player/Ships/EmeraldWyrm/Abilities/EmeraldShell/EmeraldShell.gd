class_name EmeraldShell
extends Area2D

signal shield_destroyed

@export var max_hits: int = 2
var _current_hits: int

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	_current_hits = max_hits
	animation_player.play("fade_in")

func _on_enemy_entered(entity: Node2D) -> void:
	if entity.is_in_group("Boss"):
			_take_hit(2)
	elif entity.is_in_group("Enemy") and not entity.is_in_group("Boss"):
			_take_hit(1)
			if entity.has_method("take_damage"):
				entity.take_damage(10)

func _take_hit(amount: int) -> void:
	if _current_hits <= 0: return

	_current_hits = max(0, _current_hits - amount)
	if _current_hits <= 0:
		destroy_shield()
		return
	animation_player.play("hit")

func destroy_shield() -> void:
	collision_shape.set_deferred("disabled", true)
	shield_destroyed.emit()
	animation_player.play("fade_out")
	await animation_player.animation_finished
	queue_free()

func _on_timer_timeout() -> void:
	destroy_shield()
