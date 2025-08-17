extends BaseShip

##- Constants -----------------------------------------------------------------##
const BULLET_SCENE: PackedScene = preload("res://Player/Ships/SolarDragon/Weapons/SolarPulse/SolarPulse.tscn")
const SHOOT_SOUND: AudioStream = preload("res://Player/Ships/SolarDragon/Weapons/SolarPulse/assets/Charge.ogg")


var power_orbit: float = 100.0
var charge_speed_scale: float = 1.0
var explosive_power: int = 1
##- "Virtual" Methods ---------------------------------------------------------##

func _initialize_stats() -> void:
	max_health = 10
	speed = 1200.0
	shoot_timer.wait_time = 0.5
	_base_speed = speed
	_base_shoot_cooldown = shoot_timer.wait_time

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
				&"solardragon_health_upgrade":
					max_health = effect_value
				&"solardragon_powerorbit_upgrade":
					power_orbit = effect_value
				&"solardragon_fastcharge_upgrade":
					charge_speed_scale = effect_value
				&"solardragon_explosivepower_upgrade":
					explosive_power = effect_value

func _activate_special_ability(ability_id: StringName) -> void:
	_start_ability_cooldown(ability_id)

func _initialize_audio() -> void:
	var shoot_sound_stream: AudioStream = SHOOT_SOUND
	
	for i in _shoot_audio_pool_size:
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.stream = shoot_sound_stream
		player.pitch_scale = randf_range(0.9,1.2)
		player.bus = &"efx"
		add_child(player)
		_shoot_sound_pool.append(player)

func _fire_weapon() -> void:
	if not shoot_timer.is_stopped() or not is_instance_valid(bullet_container): 
		return

	shoot_timer.start()
	_play_sound_from_pool()
	
	var bullet: SolarPulse = BULLET_SCENE.instantiate()
	bullet.setup(power_orbit,charge_speed_scale,explosive_power)
	bullet_container.add_child(bullet)
	bullet.global_position = bullet_spawn_point.global_position

##- Signal Handlers -----------------------------------------------------------##
