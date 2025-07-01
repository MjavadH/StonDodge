class_name BaseShip
extends CharacterBody2D

##- Signals -------------------------------------------------------------------##
signal died
signal health_updated(current: int, max: int)
signal took_damage

##- Constants -----------------------------------------------------------------##
const DEFAULT_BULLET_SCENE = preload("res://Player/Weapons/Projectiles/default_bullet.tscn")
const DEFAULT_SHOOT_SOUND = preload("res://Player/Weapons/Projectiles/assets/default_bullet_sound.ogg")

##- Public State (Controllable from outside) ----------------------------------##
var is_paused: bool = false

##- Base Stats (Can be overridden by child classes) ---------------------------##
var max_health: int
var health: int
var speed: float
var _base_speed: float
var _base_shoot_cooldown: float

##- Private State -------------------------------------------------------------##
var id: StringName
var _is_dead: bool = false
var _is_invincible: bool = false
var _shoot_sound_pool: Array[AudioStreamPlayer] = []
var _shoot_audio_pool_size: int = 10
# Dependencies
var bullet_container: Node

# --- original movement variables ---
var is_dragging: bool = false
var current_touch_pos: Vector2 = Vector2.ZERO
var previous_touch_pos: Vector2 = Vector2.ZERO
var screen_rect: Rect2
var target_rotation: float = 0.0
var rotation_speed: float = 10.0

##- Node References -----------------------------------------------------------##
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hit_sound: AudioStreamPlayer = $HitSound
@onready var explosion_anim: AnimatedSprite2D = $ExplosionAnim
@onready var invincibility_timer: Timer = $DamageTimer
@onready var shoot_timer: Timer = $ShootCooldown
@onready var bullet_spawn_point: Marker2D = $BulletSpawn
@onready var speed_bonus_timer: Timer = $SpeedBonusTimer
@onready var bullet_speed_bonus_timer: Timer = $BulletSpeedBonusTimer
@onready var _2x_bonus_timer: Timer = $"2xBonusTimer"

##- Godot Engine Functions ----------------------------------------------------##
func _ready():
	screen_rect = get_viewport().get_visible_rect()

func _input(event: InputEvent) -> void:
	if is_paused or _is_dead: return
	if event is InputEventScreenTouch:
		is_dragging = event.pressed
		if is_dragging:
			current_touch_pos = event.position
			previous_touch_pos = event.position
	elif event is InputEventScreenDrag:
		current_touch_pos = event.position

func _physics_process(delta):
	if is_paused or _is_dead:
		set_physics_process(false)
		return

	var input_vector = Vector2.ZERO
	target_rotation = 0
	
	if is_dragging:
		var drag_delta = current_touch_pos - previous_touch_pos
		if drag_delta.length() > 2.0:
			input_vector = drag_delta.normalized()
			velocity = input_vector * speed * 2
		else:
			velocity = Vector2.ZERO
		previous_touch_pos = current_touch_pos
	else:
		velocity = input_vector.normalized() * speed

	move_and_slide()
	_handle_animation(input_vector)

	if Input.is_action_pressed("shoot") and not _is_dead:
		_fire_weapon()
	else:
		_stop_weapon()
	
	rotation_degrees = lerp(rotation_degrees, target_rotation, rotation_speed * delta)
	var marginX = 50
	var marginY = 60
	global_position.x = clamp(global_position.x, marginX, screen_rect.size.x - marginX)
	global_position.y = clamp(global_position.y, marginY, screen_rect.size.y - marginY)

##- Public API ----------------------------------------------------------------##

func initialize(dependencies: Dictionary):
	self.bullet_container = dependencies.get("bullet_container")
	if dependencies.has("ship_id"):
		self.id = dependencies["ship_id"]
	_initialize_stats()
	_apply_purchased_upgrades()
	self.health = self.max_health
	_initialize_audio()
	health_updated.emit(health, max_health)

func take_damage(amount: int) -> void:
	if _is_dead or _is_invincible:
		return
		
	_is_invincible = true
	health = max(0, health - amount)
	health_updated.emit(health, max_health)
	
	animated_sprite.play("damaged")
	hit_sound.play()
	invincibility_timer.start()
	took_damage.emit()
	if health == 0:
		_die()

func apply_bonus(type: StringName) -> void:
	match type:
		"Speed":
			speed = _base_speed + 200 
			speed_bonus_timer.start()
		"Heal":
			if health < max_health:
				health = min(health + 1, max_health)
				health_updated.emit(health, max_health)
		"BulletSpeed":
			shoot_timer.wait_time = _base_shoot_cooldown / 2.0
			bullet_speed_bonus_timer.start()
		"2x":
			GameManager.set_score_multiplier(2)
			_2x_bonus_timer.start()

func set_paused(paused: bool) -> void:
	is_paused = paused
	# This is a critical optimization. When we pause, we stop the _physics_process
	# function. When we unpause, we re-enable it.
	set_physics_process(not is_paused)
	
	# Pause/Unpause all timers that are part of the ship's logic
	invincibility_timer.set_paused(paused)
	speed_bonus_timer.set_paused(paused)
	bullet_speed_bonus_timer.set_paused(paused)

##- "Virtual" Methods (To be overridden by child ships) -----------------------##
func _initialize_stats() -> void:
	max_health = 3
	speed = 200.0
	shoot_timer.wait_time = 0.5
	_base_speed = speed
	_base_shoot_cooldown = shoot_timer.wait_time

func _apply_purchased_upgrades() -> void:
	var ship_data: ShipData = EquipmentRegistry.get_ship_data(self.id)
	if not ship_data: return

	for upgrade_id in ship_data.available_upgrade_ids:
		# Get the level the player has purchased for this upgrade
		var purchased_level = GameManager.get_upgrade_level(ship_data.id, upgrade_id)
		
		if purchased_level > 0:
			# Get the data for this specific upgrade from the registry
			var upgrade_data: UpgradeData = UpgradeRegistry.get_upgrade_data(upgrade_id)
			if not upgrade_data: continue

			# Get the effect value for the purchased level (arrays are 0-indexed)
			var effect_value = upgrade_data.value_per_level[purchased_level - 1]
			
			# Apply the effect based on the upgrade's ID
			match upgrade_id:
				&"default_health_upgrade":
					max_health = effect_value
				&"default_firerate_upgrade":
					_base_shoot_cooldown = effect_value
					shoot_timer.wait_time = _base_shoot_cooldown
				&"default_speed_upgrade":
					_base_speed = effect_value
					speed = _base_speed

func _initialize_audio():
	var shoot_sound_stream = DEFAULT_SHOOT_SOUND
	
	for i in _shoot_audio_pool_size:
		var player := AudioStreamPlayer.new()
		player.stream = shoot_sound_stream
		player.pitch_scale = randf_range(0.9,1.2)
		player.volume_db = -15
		add_child(player)
		_shoot_sound_pool.append(player)

func _fire_weapon() -> void:
	# This is the behavior of the default ship's weapon.
	# More advanced ships can override this function entirely.
	if not shoot_timer.is_stopped() or not is_instance_valid(bullet_container): 
		return

	shoot_timer.start()
	_play_sound_from_pool()
	
	var bullet = DEFAULT_BULLET_SCENE.instantiate()
	bullet_container.add_child(bullet)
	bullet.global_position = bullet_spawn_point.global_position

func _activate_special_ability() -> void:
	# The base ship has no special ability, so this does nothing.
	pass
	
func _stop_weapon():
	pass # The base ship does nothing.

##- Private Helpers & Animation -----------------------------------------------##
func _handle_animation(dir: Vector2) -> void:
	if _is_invincible:
		animated_sprite.play("damaged")
		return
	
	if dir == Vector2.ZERO:
		animated_sprite.play("up")
	elif dir.x < 0:
		target_rotation = -15
	elif dir.x > 0:
		target_rotation = 15
	elif dir.y < 0:
		animated_sprite.play("up")
	elif dir.y > 0:
		animated_sprite.play("down")

func _die() -> void:
	if _is_dead: return
	_is_dead = true
	animated_sprite.visible = false
	explosion_anim.visible = true
	explosion_anim.play("Boom")

func _play_sound_from_pool():
	for player in _shoot_sound_pool:
		if not player.is_playing():
			player.play()
			return

##- Signal Handlers -----------------------------------------------------------##
func _on_invincibility_timer_timeout() -> void:
	_is_invincible = false

func _on_explosion_anim_animation_finished() -> void:
	died.emit()
	queue_free()

func _on_speed_bonus_timer_timeout() -> void:
	speed = _base_speed

func _on_bullet_speed_bonus_timer_timeout() -> void:
	shoot_timer.wait_time = _base_shoot_cooldown

func _on_x_bonus_timer_timeout() -> void:
	GameManager.set_score_multiplier(1)
