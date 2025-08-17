class_name VortexBoss
extends CharacterBody2D

##- Signals -------------------------------------------------------------------##
signal boss_defeated
signal health_changed(health: int)

##- Private Variables ---------------------------------------------------------##

var health: int = 400
var _is_dead: bool = false
var _projectile_scene: PackedScene

##- Dependencies --------------------------------------------------------------##
var _bullet_container: Node

##- Node References -----------------------------------------------------------##

@onready var explosion_anim: AnimatedSprite2D = $ExplosionAnim
@onready var explosion_sound: AudioStreamPlayer = $ExplosionSound
@onready var damage_area: Area2D = $BossDamageArea
@onready var boss_collision: CollisionShape2D = $CollisionShape2D
@onready var boss_damage_area_collision: CollisionShape2D = $BossDamageArea/CollisionShape2D
@onready var move_animation: AnimationPlayer = $MoveAnimation
@onready var body_node: ColorRect = $BodySprite
@onready var shoot_cooldown: Timer = $ShootCooldown
@onready var spawn_sound: AudioStreamPlayer = $SpawnSound

##- The Contract Implementation -----------------------------------------------##
func setup(dependencies: Dictionary) -> void:
	if dependencies.has("bullet_container"):
		_bullet_container = dependencies["bullet_container"]
	if dependencies.has("projectile_scene"):
		_projectile_scene = dependencies["projectile_scene"]

func set_initial_health(amount: int) -> void:
	health = amount
	health_changed.emit(health)

##- Core Logic ----------------------------------------------------------------##

func take_damage(amount: int) -> void:
	if _is_dead:
		return
	health = max(0, health - amount)
	health_changed.emit(health)
	if health == 0:
		die()

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

func _spawn_blackhole():
	var viewport_rect: Vector2 = get_viewport_rect().size
	var projectile = _projectile_scene.instantiate()
	_bullet_container.add_child(projectile)
	projectile.global_position = Vector2(randf_range(100, viewport_rect.x - 100),randf_range(400, viewport_rect.y - 50))
	spawn_sound.play()

##- Signal Handlers -----------------------------------------------------------##

func _on_explosion_anim_animation_finished() -> void:
	queue_free()

func _on_shoot_cooldown_timeout() -> void:
	for i in randi() % 15 + 4:
		_spawn_blackhole()
	shoot_cooldown.start(randf_range(1.5,3.0))
