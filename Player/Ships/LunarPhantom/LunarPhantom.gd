class_name LunarPhantom
extends BaseShip

##- Constants -----------------------------------------------------------------##
const LASER_BEAM_SCENE: PackedScene = preload("res://Player/Ships/LunarPhantom/Weapons/LunarPhantom_LaserBeam.tscn")
const RUNIC_BOMB_SCENE: PackedScene = preload("res://Player/Ships/LunarPhantom/Abilities/RunicBomb/RunicBomb.tscn")

@export var charge_time: float = 2.5 # Time in seconds to charge the laser
@export var fire_duration: float = 20.0 # How long the laser stays active
@export var cooldown_duration: float = 3.0 # Cooldown AFTER firing

##- State Machine for Weapon --------------------------------------------------##
enum WeaponState { IDLE, CHARGING, FIRING, COOLDOWN }
var _weapon_state: WeaponState = WeaponState.IDLE
var _active_laser_beam: LaserBeam = null

##- Node References -----------------------------------------------------------##
@onready var charge_timer: Timer = $ChargeTimer
@onready var charge_sound_player: AudioStreamPlayer = $ChargeSoundPlayer
@onready var continuous_shoot_sound_player: AudioStreamPlayer = $ContinuousShootSoundPlayer
@onready var invisibility_timer: Timer = $InvisibilityTimer
@onready var fire_timer: Timer = $FireTimer
@onready var stop_fire_sound_player: AudioStreamPlayer = $StopFireSoundPlayer
@onready var invisibility_sound_player: AudioStreamPlayer = $InvisibilitySoundPlayer

##- "Virtual" Methods Overridden ----------------------------------------------##

func _initialize_stats() -> void:
	super._initialize_stats()
	max_health = 8
	speed = 900.0
	_base_speed = speed
	charge_timer.wait_time = charge_time
	fire_timer.wait_time = fire_duration
	shoot_timer.wait_time = cooldown_duration

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
				&"lunarphantom_firing_duration_upgrade":
					fire_duration = effect_value
					fire_timer.wait_time = fire_duration
				&"lunarphantom_speed_upgrade":
					_base_speed = effect_value
					speed = _base_speed

func _activate_special_ability(ability_id: StringName) -> void:
	match ability_id:
		&"invisibility":
			invisibility_timer.start()
			self.modulate = Color.hex(0x0069d9a0)
			self.set_collision_layer_value(5, true)
			self.set_collision_layer_value(1, false)
			invisibility_sound_player.play()
		&"RunicExplosion":
			var bomb_instance: RunicBomb = RUNIC_BOMB_SCENE.instantiate()
			bomb_instance.global_position = self.global_position
			abilities_container.add_child(bomb_instance)
	
	_start_ability_cooldown(ability_id)

func _recalculate_stats() -> void:
	super._recalculate_stats()
	shoot_timer.wait_time = cooldown_duration

func _fire_weapon() -> void:
	match _weapon_state:
		WeaponState.IDLE:
			# Do not start charging if the main cooldown is active.
			if not shoot_timer.is_stopped():
				return
			# If cooldown is over, begin charging.
			_change_weapon_state(WeaponState.CHARGING)
			
		WeaponState.FIRING:
			if is_instance_valid(_active_laser_beam):
				_active_laser_beam.global_position = bullet_spawn_point.global_position
				_active_laser_beam.update_beam(bullet_spawn_point.global_position)
				var heat: float = 1.0 - (fire_timer.time_left / fire_timer.wait_time)
				var laser_material: ShaderMaterial = _active_laser_beam.visual.material as ShaderMaterial
				if laser_material:
					laser_material.set_shader_parameter("heat_progress", heat)

func _stop_weapon() -> void:
	if _weapon_state == WeaponState.CHARGING or _weapon_state == WeaponState.FIRING:
		_cleanup_laser()
		_change_weapon_state(WeaponState.IDLE)

##- State Machine Logic -------------------------------------------------------##

func _change_weapon_state(new_state: WeaponState) -> void:
	if _weapon_state == new_state: return
	
	_weapon_state = new_state

	match new_state:
		WeaponState.CHARGING:
			_active_laser_beam = LASER_BEAM_SCENE.instantiate()
			bullet_container.add_child(_active_laser_beam)
			charge_timer.start()
			charge_sound_player.play()
		
		WeaponState.FIRING:
			if is_instance_valid(_active_laser_beam):
				_active_laser_beam.activate()
			continuous_shoot_sound_player.play()
			fire_timer.start() # Start the timer for how long the beam stays active.
			
		WeaponState.COOLDOWN:
			# When entering cooldown, clean up the laser and start the main cooldown timer.
			_cleanup_laser()
			shoot_timer.start()

##- Private Helpers -----------------------------------------------------------##

func _cleanup_laser() -> void:
	if is_instance_valid(_active_laser_beam):
		_active_laser_beam.deactivate()
		_active_laser_beam.queue_free()
		_active_laser_beam = null
	
	continuous_shoot_sound_player.stop()
	charge_sound_player.stop()
	charge_timer.stop()
	fire_timer.stop()

##- Signal Handlers -----------------------------------------------------------##

func _on_charge_timer_timeout() -> void:
	if _weapon_state == WeaponState.CHARGING:
		_change_weapon_state(WeaponState.FIRING)

func _on_fire_timer_timeout() -> void:
	if _weapon_state == WeaponState.FIRING:
		_change_weapon_state(WeaponState.COOLDOWN)
		_is_cooldown = true
		stop_fire_sound_player.play()
		animated_sprite.play(&"cooldown")

func _on_shoot_cooldown_timeout() -> void:
	_change_weapon_state(WeaponState.IDLE)
	_is_cooldown = false

func _on_invisibility_timer_timeout() -> void:
	self.modulate = Color.WHITE
	self.set_collision_layer_value(1, true)
	self.set_collision_layer_value(5, false)
