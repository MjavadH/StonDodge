class_name Meteor
extends Area2D

signal meteor_destroyed(score_value: int, global_pos: Vector2)
signal bonus_dropped(position: Vector2)

# --- Internal State ---
var health: int
var _max_health: int
var _score_value: int
var _is_bonus_carrier: bool
var _is_dead: bool = false
var _speed: float
var _base_speed: float

# --- Node References ---
@onready var sprite: Sprite2D = $Sprite2D
@onready var explosion_anim: AnimatedSprite2D = $ExplosionAnim
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var explosion_sound: AudioStreamPlayer = $ExplosionSound

##- Public API & Initialization -----------------------------------------------##

func initialize(data: MeteorData) -> void:
	sprite.texture = data.texture
	_max_health = data.health
	health = _max_health
	_score_value = data.score_value
	_is_bonus_carrier = data.is_bonus_carrier
	explosion_anim.animation = data.explosion_anim_name
	
	# Set a random scale and speed.
	var random_scale: float = randf_range(0.7, 1.05)
	scale = Vector2(random_scale, random_scale)
	_base_speed = randf_range(160.0, 320.0)
	
	# Initialize shader
	if sprite.material:
		sprite.material = sprite.material.duplicate()
	var mat: ShaderMaterial = sprite.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("progress", 0.0)
		mat.set_shader_parameter("seed", randf() * 100.0)
		mat.set_shader_parameter("step", _max_health)
		mat.set_shader_parameter("crack_color",data.crack_color)
		if GameManager.current_quality_level == GameManager.QualityLevel.LOW:
			mat.set_shader_parameter("high_quality",true)

func is_dead() -> bool:
	return _is_dead

##- Godot Engine Functions ----------------------------------------------------##

func _physics_process(delta: float) -> void:
	_speed = _base_speed * GameManager.get_slow_mo_multiplier()
	position.y += _speed * delta
	sprite.rotation += delta

##- Core Logic ----------------------------------------------------------------##

func take_damage(amount: int) -> void:
	if _is_dead: return
	health = max(0, health - amount)
	
	var mat: ShaderMaterial = sprite.material as ShaderMaterial
	if mat:
		var damage_ratio: float = 1.0 - (float(health) / float(_max_health))
		mat.set_shader_parameter("progress", damage_ratio)
		
	if health == 0:
		call_deferred("_die")

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") and not _is_dead:
		if body.has_method("take_damage"):
			body.take_damage(1)
		take_damage(1)

func _die() -> void:
	if _is_dead: return
	_is_dead = true
	
	collision_shape.set_deferred("disabled", true)
	self.monitorable = false
	self.monitoring = false
	set_physics_process(false)
	
	meteor_destroyed.emit(_score_value, global_position)
	GameManager.add_score_from_enemy(_score_value)
	
	if _is_bonus_carrier:
		bonus_dropped.emit(global_position)
	
	sprite.visible = false
	explosion_anim.visible = true
	explosion_anim.play() # The animation name is already set in initialize()
	explosion_sound.play()

func _on_explosion_anim_animation_finished() -> void:
	queue_free()
