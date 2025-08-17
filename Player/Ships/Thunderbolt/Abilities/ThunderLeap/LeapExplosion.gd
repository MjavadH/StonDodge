class_name LeapExplosion
extends Node2D

@export var damage: int = 2
@export var arming_delay: float = 0.1 # A short delay to allow the physics server to update.

enum State { ARMING, ACTIVE, FINISHED }
var _current_state = State.ARMING

@onready var damage_area: Area2D = $DamageArea
@onready var animation: AnimatedSprite2D = $AnimatedSprite2D
@onready var sound: AudioStreamPlayer = $AudioStreamPlayer
@onready var arming_timer: Timer = $ArmingTimer

func _ready() -> void:
	arming_timer.wait_time = arming_delay
	arming_timer.start()
	animation.play("explode")
	sound.play()

func _on_arming_finished():
	_current_state = State.ACTIVE
	_deal_damage()
	await animation.animation_finished
	_current_state = State.FINISHED
	queue_free()

func _deal_damage():
	if _current_state != State.ACTIVE:
		return
	var targets = damage_area.get_overlapping_bodies() + damage_area.get_overlapping_areas()
	for target in targets:
		if target.is_in_group("Enemy") and target.has_method("take_damage"):
			if not target.get("_is_dead"):
				target.take_damage(damage)
