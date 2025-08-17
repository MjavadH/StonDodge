extends BaseShip

##- Constants -----------------------------------------------------------------##
const BULLET_SCENE: PackedScene = preload("res://Player/Ships/Thunderbolt/Weapons/Thunderbolt_bullet.tscn")
const SHOOT_SOUND: AudioStream = preload("res://Player/Ships/Thunderbolt/assets/Thunderbolt_bullet_sound.ogg")
const THUNDERSTORM_SOUND: AudioStream = preload("res://Player/Ships/Thunderbolt/assets/ThunderstormSound.ogg")
const LEAP_EFFECT_SCENE: PackedScene = preload("res://Player/Ships/Thunderbolt/Abilities/ThunderLeap/LeapExplosion.tscn")

@export_group("Thunder Leap")
@export var leap_distance_ratio: float = 0.2 # 20% of the screen height
@export var leap_damage: int = 10

@onready var thunderstorm_timer: Timer = $ThunderstormTimer
@onready var thunderstorm_cooldown_timer: Timer = $ThunderstormCooldownTimer
@onready var thunder_leap_sound: AudioStreamPlayer = $ThunderLeapSound

var _bullet_length: int
var top_spawner: PathFollow2D
var _thunderstorm_sound_pool: Array[AudioStreamPlayer] = []
var _thunderstorm_audio_pool_size: int = 6
##- "Virtual" Methods ---------------------------------------------------------##

func _initialize_stats() -> void:
	super._initialize_stats()
	max_health = 5
	speed = 700.0
	_bullet_length = 500

func _apply_purchased_upgrades() -> void:
	var ship_data: ShipData = EquipmentRegistry.get_ship_data(self.id)
	if not ship_data: return
	for upgrade_id in ship_data.available_upgrade_ids:
		var purchased_level = GameManager.get_upgrade_level(ship_data.id, upgrade_id)
		if purchased_level > 0:
			var upgrade_data: UpgradeData = UpgradeRegistry.get_upgrade_data(upgrade_id)
			if not upgrade_data: continue
			var effect_value = upgrade_data.value_per_level[purchased_level - 1]
			match upgrade_id:
				&"thunderbolt_health_upgrade":
					max_health = effect_value
				&"default_firerate_upgrade":
					_base_shoot_cooldown = effect_value
					shoot_timer.wait_time = _base_shoot_cooldown
				&"thunderbolt_speed_upgrade":
					_base_speed = effect_value
					speed = _base_speed
				&"thunderbolt_bullet_length_upgrade":
					_bullet_length = effect_value

func _activate_special_ability(ability_id: StringName) -> void:
	match ability_id:
		&"Thunderstorm":
			thunderstorm_cooldown_timer.start()
			thunderstorm_timer.start()
		&"thunder_leap":
			_is_invincible = true
			_execute_thunder_leap()

	_start_ability_cooldown(ability_id)

func _initialize_audio() -> void:
	var shoot_sound_stream: AudioStream = SHOOT_SOUND
	var thunderstorm_sound_stream: AudioStream = THUNDERSTORM_SOUND
	for i in _shoot_audio_pool_size:
		var shoot_player: AudioStreamPlayer = AudioStreamPlayer.new()
		shoot_player.stream = shoot_sound_stream
		shoot_player.pitch_scale = randf_range(0.9,1.2)
		shoot_player.bus = &"efx"
		add_child(shoot_player)
		_shoot_sound_pool.append(shoot_player)
	for i in _thunderstorm_audio_pool_size:
		var thunderstorm_player: AudioStreamPlayer = AudioStreamPlayer.new()
		thunderstorm_player.stream = thunderstorm_sound_stream
		thunderstorm_player.pitch_scale = randf_range(0.9,1.2)
		thunderstorm_player.bus = &"efx"
		add_child(thunderstorm_player)
		_thunderstorm_sound_pool.append(thunderstorm_player)

func _fire_weapon() -> void:
	if not shoot_timer.is_stopped() or not is_instance_valid(bullet_container): 
		return
	
	var bullet = BULLET_SCENE.instantiate()
	bullet_container.add_child(bullet)
	bullet.fire(bullet_spawn_point.global_position,Vector2.UP,_bullet_length)
	shoot_timer.start()
	_play_sound_from_pool()

func _play_thunderstorm_sound_from_pool() -> void:
	for player in _thunderstorm_sound_pool:
		if not player.is_playing():
			player.play()
			return

func _on_thunderstorm_cooldown_timer_timeout() -> void:
	var bullet = BULLET_SCENE.instantiate()
	bullet_container.add_child(bullet)
	if _dependencies.has("top_spawner"):
		top_spawner = _dependencies["top_spawner"]
		top_spawner.progress_ratio = randf()
		bullet.fire(top_spawner.global_position,Vector2.DOWN,randf_range(400, _bullet_length * 1.4))
		_play_thunderstorm_sound_from_pool()

func _execute_thunder_leap():
	_spawn_leap_explosion(global_position)
	var screen_height = get_viewport_rect().size.y
	var leap_vector = Vector2.UP * screen_height * leap_distance_ratio
	global_position += leap_vector
	thunder_leap_sound.play()
	_spawn_leap_explosion(global_position)

func _spawn_leap_explosion(pos: Vector2):
	var explosion: LeapExplosion = LEAP_EFFECT_SCENE.instantiate()
	explosion.damage = leap_damage
	explosion.global_position = pos
	get_tree().current_scene.add_child(explosion)
	self.modulate = Color.from_rgba8(190,0,255,128)
	await get_tree().create_timer(1.5).timeout
	_is_invincible = false
	self.modulate = Color.WHITE

func _on_thunderstorm_timer_timeout() -> void:
	thunderstorm_cooldown_timer.stop()
