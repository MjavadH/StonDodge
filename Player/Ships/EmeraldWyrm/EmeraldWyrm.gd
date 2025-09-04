extends BaseShip

##- Constants -----------------------------------------------------------------##
const BULLET_SCENE: PackedScene = preload("res://Player/Ships/EmeraldWyrm/Weapons/EmeraldWyrm_bullet.tscn")
const SHOOT_SOUND: AudioStream = preload("res://Player/Ships/EmeraldWyrm/assets/Emerald-Wyrm_bullet_sound.ogg")
const EMERALDSHELL_SCENE: PackedScene = preload("res://Player/Ships/EmeraldWyrm/Abilities/EmeraldShell/EmeraldShell.tscn")
const GEAROVERCLOCK_ON: AudioStream = preload("res://Player/Ships/EmeraldWyrm/assets/GearOverclock_On.ogg")
const GEAROVERCLOCK_OFF: AudioStream = preload("res://Player/Ships/EmeraldWyrm/assets/GearOverclock_Off.ogg")

@onready var gear_overclock_timer: Timer = $GearOverclockTimer
@onready var gear_overclock_sound_player: AudioStreamPlayer = $GearOverclockSoundPlayer

var _active_shield_instance: EmeraldShell = null
var _is_overclock_active: bool = false

##- "Virtual" Methods ---------------------------------------------------------##

func _initialize_stats() -> void:
	max_health = 4
	speed = 500.0
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
				&"emeraldwyrm_health_upgrade":
					max_health = effect_value
				&"default_firerate_upgrade":
					_base_shoot_cooldown = effect_value
					shoot_timer.wait_time = _base_shoot_cooldown
				&"thunderbolt_speed_upgrade":
					_base_speed = effect_value
					speed = _base_speed

func _activate_special_ability(ability_id: StringName) -> void:
	match ability_id:
		&"emerald_shell":
			if is_instance_valid(_active_shield_instance):
				return
	
			_active_shield_instance = EMERALDSHELL_SCENE.instantiate()
			add_child(_active_shield_instance)
			
			_active_shield_instance.shield_destroyed.connect(_on_shield_destroyed)
		&"GearOverclock":
			_is_overclock_active = true
			gear_overclock_sound_player.stream = GEAROVERCLOCK_ON
			gear_overclock_sound_player.play()
			gear_overclock_timer.start()
			_recalculate_stats()
	
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

func _recalculate_stats() -> void:
	super._recalculate_stats()
	
	if _is_overclock_active:
		speed *= 1.3
		shoot_timer.wait_time *= 0.7

func _fire_weapon() -> void:
	if not shoot_timer.is_stopped() or not is_instance_valid(bullet_container): 
		return

	shoot_timer.start()
	_play_sound_from_pool()
	
	var bullet = BULLET_SCENE.instantiate()
	bullet_container.add_child(bullet)
	bullet.global_position = bullet_spawn_point.global_position
	
##- Signal Handlers -----------------------------------------------------------##

func _on_shield_destroyed() -> void:
	_is_invincible = false
	_active_shield_instance = null

func _on_gear_overclock_timer_timeout() -> void:
	_is_overclock_active = false
	gear_overclock_sound_player.stream = GEAROVERCLOCK_OFF
	gear_overclock_sound_player.play()
	_recalculate_stats()
