class_name BaseShip
extends CharacterBody2D

##- Signals -------------------------------------------------------------------##
signal died
signal health_updated(current: int, max: int)
signal took_damage
signal request_drone
# Emitted when an ability is successfully activated.
signal ability_activated(ability_id: StringName)
# Emitted when a cooldown finishes and an ability is ready again.
signal ability_ready(ability_id: StringName)


##- Constants -----------------------------------------------------------------##
const DEFAULT_BULLET_SCENE : PackedScene = preload("res://Player/Ships/Default/Weapons/default_bullet.tscn")
const DEFAULT_SHOOT_SOUND: AudioStream = preload("res://Player/Ships/Default/assets/default_bullet_sound.ogg")
const STOP_THRESHOLD = 5.0
const HORIZONTAL_THRESHOLD = 0.3

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
var _is_cooldown: bool = false
var _is_invincible: bool = false
var _is_took_damage: bool = false
var _is_speed_bonus_active: bool = false
var _is_bullet_speed_bonus_active: bool = false
var _shoot_sound_pool: Array[AudioStreamPlayer] = []
var _shoot_audio_pool_size: int = 8
var _ability_cooldown_timers: Dictionary = {}
#  --- Dependencies ---
var _dependencies: Dictionary
var bullet_container: Node
var abilities_container: Node

# --- original movement variables ---
var is_dragging: bool = false
var current_drag_direction: Vector2 = Vector2.ZERO
var previous_drag_direction: Vector2 = Vector2.ZERO
var _drag_touch_index: int = -1
var acceleration: float = 10.0 # How quickly the ship reacts to input.
var target_rotation: float = 0.0
var rotation_speed: float = 10.0

# --- screen variables ---
var screen_rect: Rect2
var marginX: int = 50
var marginY: int = 70

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
func _ready() -> void:
	screen_rect = get_viewport().get_visible_rect()

func _input(event: InputEvent) -> void:
	if is_paused or _is_dead: return

	if event is InputEventScreenTouch and event.pressed:
		if _drag_touch_index == -1:
			is_dragging = true
			_drag_touch_index = event.index

	elif event is InputEventScreenTouch and not event.pressed:
		if event.index == _drag_touch_index:
			is_dragging = false
			current_drag_direction = Vector2.ZERO
			previous_drag_direction = Vector2.ZERO
			_drag_touch_index = -1
			
	elif event is InputEventScreenDrag:
		if event.index == _drag_touch_index:
			current_drag_direction = event.relative
			

func _physics_process(delta: float) -> void:
	if is_paused or _is_dead:
		set_physics_process(false)
		return
	
	target_rotation = 0
	var target_velocity: Vector2
	
	if is_dragging and current_drag_direction != Vector2.ZERO and current_drag_direction != previous_drag_direction:
		target_velocity = current_drag_direction.normalized() * speed
	else:
		target_velocity = Vector2.ZERO
	previous_drag_direction = current_drag_direction
	velocity = velocity.lerp(target_velocity, delta * acceleration)
	
	move_and_slide()
	_handle_animation(target_velocity)

	if Input.is_action_pressed("shoot") and not _is_dead:
		_fire_weapon()
	else:
		_stop_weapon()
	
	rotation_degrees = lerp(rotation_degrees, target_rotation, rotation_speed * delta)
	global_position.x = clamp(global_position.x, marginX, screen_rect.size.x - marginX)
	global_position.y = clamp(global_position.y, marginY, screen_rect.size.y - marginY)

##- Public API ----------------------------------------------------------------##

func initialize(dependencies: Dictionary) -> void:
	_dependencies = dependencies
	self.bullet_container = dependencies.get("bullet_container")
	self.abilities_container = dependencies.get("abilities_container")
	if dependencies.has("ship_id"):
		self.id = dependencies["ship_id"]
	_initialize_stats()
	_apply_purchased_upgrades()
	_initialize_abilities()
	self.health = self.max_health
	_initialize_audio()
	health_updated.emit(health, max_health)

func take_damage(amount: int) -> void:
	if _is_dead or _is_invincible:
		return
		
	_is_invincible = true
	_is_took_damage = true
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
			_is_speed_bonus_active = true
			speed_bonus_timer.start()
		"Heal":
			if health < max_health:
				health = min(health + 1, max_health)
				health_updated.emit(health, max_health)
		"BulletSpeed":
			_is_bullet_speed_bonus_active = true
			bullet_speed_bonus_timer.start()
		"2x":
			GameManager.set_score_multiplier(GameManager.get_score_multiplier() * 2)
			_2x_bonus_timer.start()
		"Mini-Drone":
			request_drone.emit()
	_recalculate_stats()

func set_paused(paused: bool) -> void:
	is_paused = paused
	# This is a critical optimization. When we pause, we stop the _physics_process
	# function. When we unpause, we re-enable it.
	set_physics_process(not is_paused)
	
	# Pause/Unpause all timers that are part of the ship's logic
	invincibility_timer.set_paused(paused)
	speed_bonus_timer.set_paused(paused)
	bullet_speed_bonus_timer.set_paused(paused)

func try_activate_ability(ability_id: StringName) -> void:
	# Check if the ability is on cooldown.
	if _ability_cooldown_timers.has(ability_id) and not _ability_cooldown_timers[ability_id].is_stopped():
		return
	_activate_special_ability(ability_id)

##- "Virtual" Methods (To be overridden by child ships) -----------------------##
func _initialize_stats() -> void:
	max_health = 3
	speed = 500.0
	shoot_timer.wait_time = 0.5
	_base_speed  = speed
	_base_shoot_cooldown  = shoot_timer.wait_time

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
				&"default_speed_upgrade":
					_base_speed = effect_value
			_recalculate_stats()

func _initialize_audio() -> void:
	var shoot_sound_stream: AudioStream = DEFAULT_SHOOT_SOUND
	
	for i in _shoot_audio_pool_size:
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.stream = shoot_sound_stream
		player.pitch_scale = randf_range(0.9,1.2)
		player.bus = &"efx"
		add_child(player)
		_shoot_sound_pool.append(player)

func _recalculate_stats() -> void:
	var final_speed: float = _base_speed
	var final_cooldown: float = _base_shoot_cooldown
	
	if _is_speed_bonus_active:
		final_speed += 200.0
	
	if _is_bullet_speed_bonus_active:
		final_cooldown /= 2.0
		
	speed = final_speed
	shoot_timer.wait_time = final_cooldown

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

func _activate_special_ability(ability_id: StringName) -> void:
	# The base ship has no special ability, so this does nothing.
	pass

func _stop_weapon() -> void:
	pass # The base ship does nothing.

##- Private Helpers & Animation -----------------------------------------------##
func _handle_animation(current_velocity: Vector2) -> void:
	if _is_took_damage:
		animated_sprite.play("damaged")
		return

	if current_velocity.length() < STOP_THRESHOLD and not _is_cooldown:
		animated_sprite.play("up")
		target_rotation = 0
		return
	var dir = current_velocity.normalized()
	
	# --- HORIZONTAL ROTATION LOGIC (Always runs when moving) ---
	
	if abs(dir.x) > HORIZONTAL_THRESHOLD:
		if dir.x < 0:
			target_rotation = -20
		else:
			target_rotation = 20
	else:
		target_rotation = 0
	
	# --- VERTICAL ANIMATION LOGIC (Only runs when NOT on cooldown) ---
	if not _is_cooldown:
		if dir.y > 0.5:
			animated_sprite.play("down")
		else:
			# The "up" animation serves as the default forward-moving animation.
			animated_sprite.play("up")

func _initialize_abilities() -> void:
	var ship_data: ShipData = EquipmentRegistry.get_ship_data(self.id)
	if not ship_data: return

	for ability_data in ship_data.abilities:
		# Create a new Timer node for each ability to manage its cooldown.
		var cooldown_timer: Timer = Timer.new()
		cooldown_timer.name = "%sCooldownTimer" % ability_data.id
		cooldown_timer.wait_time = ability_data.cooldown_duration
		cooldown_timer.one_shot = true
		add_child(cooldown_timer)
		
		# Connect the timeout signal to a generic handler.
		cooldown_timer.timeout.connect(func() -> void:
			ability_ready.emit(ability_data.id)
		)
		
		# Store the timer in our dictionary for easy access.
		_ability_cooldown_timers[ability_data.id] = cooldown_timer

func _start_ability_cooldown(ability_id: StringName) -> void:
	if _ability_cooldown_timers.has(ability_id):
		_ability_cooldown_timers[ability_id].start()
		ability_activated.emit(ability_id)

func _die() -> void:
	if _is_dead: return
	_is_dead = true
	animated_sprite.visible = false
	explosion_anim.visible = true
	explosion_anim.play("Boom")

func _play_sound_from_pool() -> void:
	for player in _shoot_sound_pool:
		if not player.is_playing():
			player.play()
			return

##- Signal Handlers -----------------------------------------------------------##
func _on_invincibility_timer_timeout() -> void:
	_is_invincible = false
	_is_took_damage = false

func _on_explosion_anim_animation_finished() -> void:
	died.emit()
	queue_free()

func _on_speed_bonus_timer_timeout() -> void:
	_is_speed_bonus_active = false
	_recalculate_stats()

func _on_bullet_speed_bonus_timer_timeout() -> void:
	_is_bullet_speed_bonus_active = false
	_recalculate_stats()

func _on_x_bonus_timer_timeout() -> void:
	GameManager.set_score_multiplier(GameManager.get_score_multiplier() / 2)
