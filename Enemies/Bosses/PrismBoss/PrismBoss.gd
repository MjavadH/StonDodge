class_name PrismBoss
extends CharacterBody2D

##- Signals -------------------------------------------------------------------##
signal boss_defeated
signal health_changed(health: int)

##- Private Variables ---------------------------------------------------------##
var health: int = 300
var _is_dead: bool = false
var _character_node: CharacterBody2D
var _bullet_container: Node
var _bullet_scene: PackedScene

##- Node References -----------------------------------------------------------##
@onready var body: Sprite2D = $Sprite2D
@onready var shoot_cooldown: Timer = $ShootCooldown
@onready var damage_area: Area2D = $BossDamageArea
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var bullet_spawn_point: Marker2D = $Marker2D/BulletSpawn
@onready var explosion_anim: AnimatedSprite2D = $ExplosionAnim
@onready var explosion_sound: AudioStreamPlayer = $ExplosionSound
@onready var boss_collision: CollisionPolygon2D = $CollisionPolygon2D
@onready var boss_damage_area_collision: CollisionPolygon2D = $BossDamageArea/CollisionPolygon2D

##- The Contract Implementation -----------------------------------------------##
func setup(dependencies: Dictionary) -> void:
	if dependencies.has("character"):
		_character_node = dependencies["character"]
	if dependencies.has("bullet_container"):
		_bullet_container = dependencies["bullet_container"]
	if dependencies.has("projectile_scene"):
		_bullet_scene = dependencies["projectile_scene"]

func set_initial_health(amount: int) -> void:
	health = amount
	health_changed.emit(health)

func start() -> void:
	animation_player.play("ShowSelf")
	# Start the attack pattern only after the intro animation is finished.
	animation_player.animation_finished.connect(_on_intro_animation_finished, CONNECT_ONE_SHOT)

##- Godot Engine Functions ----------------------------------------------------##
func _physics_process(_delta: float) -> void:
	if not _is_dead and is_instance_valid(_character_node):
		look_at(_character_node.global_position)

##- Public Functions ----------------------------------------------------------##

func take_damage(amount: int) -> void:
	if _is_dead:
		return
	health = max(0, health - amount)
	health_changed.emit(health)
	if health == 0:
		die()

##- Private Functions ---------------------------------------------------------##

func _shoot_bullet() -> void:
	if _is_dead or not is_instance_valid(_character_node) or not _bullet_scene:
		return

	var bullet: Node2D = _bullet_scene.instantiate()
	_bullet_container.add_child(bullet)

	bullet.global_position = bullet_spawn_point.global_position
	var direction_to_player: Vector2 = _character_node.global_position - bullet_spawn_point.global_position

	# Call the bullet's own setup method to set its direction.
	if bullet.has_method("set_direction"):
		bullet.set_direction(direction_to_player)
	
	# Rotate the bullet sprite to face the player.
	bullet.rotation = direction_to_player.angle() + deg_to_rad(90)

func die() -> void:
	if _is_dead:
		return
	_is_dead = true
	
	shoot_cooldown.stop()
	boss_defeated.emit()
	explosion_sound.play()
	
	boss_collision.set_deferred("disabled", true)
	boss_damage_area_collision.set_deferred("disabled", true)
	damage_area.monitorable = false
	damage_area.monitoring = false
	
	body.visible = false
	explosion_anim.visible = true
	explosion_anim.play("destroyed")

##- Signal Handlers -----------------------------------------------------------##

func _on_intro_animation_finished(anim_name: StringName) -> void:
	if anim_name == "ShowSelf":
		shoot_cooldown.start(randf_range(0.3, 0.5))

func _on_shoot_cooldown_timeout() -> void:
	_shoot_bullet()
	shoot_cooldown.start(randf_range(0.3, 0.5))

func _on_explosion_anim_animation_finished() -> void:
	queue_free()
