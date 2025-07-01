extends BaseShip

##- Constants -----------------------------------------------------------------##
const BULLET_SCENE = preload("res://Player/Weapons/Projectiles/Thunderbolt_bullet.tscn")
const SHOOT_SOUND = preload("res://Player/Weapons/Projectiles/assets/Thunderbolt_bullet_sound.ogg")

var _bullet_length: int
##- "Virtual" Methods ---------------------------------------------------------##

func _initialize_stats() -> void:
	super._initialize_stats()
	max_health = 5
	speed = 300.0
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

func _initialize_audio():
	var shoot_sound_stream = SHOOT_SOUND
	for i in _shoot_audio_pool_size:
		var player := AudioStreamPlayer.new()
		player.stream = shoot_sound_stream
		player.pitch_scale = randf_range(0.9,1.2)
		player.volume_db = -15
		add_child(player)
		_shoot_sound_pool.append(player)

func _fire_weapon() -> void:
	if not shoot_timer.is_stopped() or not is_instance_valid(bullet_container): 
		return
	shoot_timer.start()
	_play_sound_from_pool()
	
	var bullet = BULLET_SCENE.instantiate()
	bullet_container.add_child(bullet)
	bullet.fire(bullet_spawn_point.global_position,Vector2.UP,_bullet_length)
