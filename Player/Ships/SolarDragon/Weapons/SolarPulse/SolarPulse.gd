class_name SolarPulse
extends Area2D

const SPEED: int = 1500
var Damage: int = 1
var animation_speed_scale: float = 1.0
var collision_radius: float = 100
enum State { CHARGING, FIRING, DETONATED }
var _current_state = State.CHARGING

@onready var animations: AnimatedSprite2D = $Animations
@onready var visual: Sprite2D = $Visual
@onready var shoot_sound: AudioStreamPlayer = $ShootSound
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var damage_area: Area2D = $DamageArea
@onready var collision_shape_2d: CollisionShape2D = $DamageArea/CollisionShape2D

func setup(power_orbit: float,charge_speed_scale: float,explosive_power:int) -> void:
	animation_speed_scale = charge_speed_scale
	collision_radius = power_orbit
	Damage = explosive_power

func _ready() -> void:
	visual.visible = false
	animations.speed_scale = animation_speed_scale
	collision_shape_2d.shape.set("radius",collision_radius)
	animations.play("Start")

func _process(delta: float) -> void:
	if _current_state == State.FIRING:
		position.y -= SPEED * delta

func _on_animations_animation_finished() -> void:
	if animations.animation == &"Start":
		_current_state = State.FIRING
		visual.visible = true
		shoot_sound.play()
		animations.visible = false

func _on_impact(target: Node2D):
	if _current_state != State.FIRING:
		return
	if target.is_in_group("Enemy"):
		_current_state = State.DETONATED
		set_physics_process(false)
		collision_shape.set_deferred("disabled", true)
		call_deferred("_explode")

func _explode():
	set_physics_process(false)
	collision_shape.set_deferred("disabled", true)
	
	visual.visible = false

	var targets_in_radius = damage_area.get_overlapping_bodies() + damage_area.get_overlapping_areas()
	
	for target in targets_in_radius:
		if target.is_in_group("Enemy") and not target.get("_is_dead"):
			if target.has_method("take_damage"):
				target.take_damage(Damage)
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	_on_impact(body)

func _on_area_entered(area: Area2D) -> void:
	_on_impact(area)
