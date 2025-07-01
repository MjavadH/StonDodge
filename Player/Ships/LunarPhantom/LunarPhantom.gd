class_name LunarPhantom
extends BaseShip

##- Constants -----------------------------------------------------------------##
const LASER_BEAM_SCENE = preload("res://Player/Weapons/Projectiles/LunarPhantom_LaserBeam.tscn")

@export var charge_time: float = 5 # Time in seconds to charge the laser

##- State Machine for Weapon --------------------------------------------------##
enum WeaponState { IDLE, CHARGING, FIRING }
var _weapon_state = WeaponState.IDLE
var _active_laser_beam: LaserBeam = null

##- Node References -----------------------------------------------------------##
@onready var charge_timer: Timer = $ChargeTimer
@onready var charge_sound_player: AudioStreamPlayer = $ChargeSoundPlayer
@onready var continuous_shoot_sound_player: AudioStreamPlayer = $ContinuousShootSoundPlayer

##- "Virtual" Methods Overridden ----------------------------------------------##

func _initialize_stats() -> void:
	super._initialize_stats()
	max_health = 8
	speed = 550.0
	_base_speed = speed
	charge_timer.wait_time = charge_time

func _fire_weapon() -> void:
	match _weapon_state:
		WeaponState.IDLE:
			# If player starts holding the button, begin charging.
			_weapon_state = WeaponState.CHARGING
			_active_laser_beam = LASER_BEAM_SCENE.instantiate()
			bullet_container.add_child(_active_laser_beam)
			charge_timer.start()
			charge_sound_player.play()
		
		WeaponState.CHARGING:
			pass
			
		WeaponState.FIRING:
			if is_instance_valid(_active_laser_beam):
				_active_laser_beam.global_position = bullet_spawn_point.global_position
				_active_laser_beam.update_beam(bullet_spawn_point.global_position)

func _stop_weapon() -> void:
	if _weapon_state == WeaponState.IDLE:
		return

	if is_instance_valid(_active_laser_beam):
		_active_laser_beam.deactivate()
		_active_laser_beam.queue_free()
		_active_laser_beam = null
		
	continuous_shoot_sound_player.stop() # Stop the continuous laser sound
	charge_sound_player.stop()
	charge_timer.stop()
	
	_weapon_state = WeaponState.IDLE

##- Signal Handlers -----------------------------------------------------------##

func _on_charge_timer_timeout():
	if _weapon_state == WeaponState.CHARGING:
		_weapon_state = WeaponState.FIRING
		
		if is_instance_valid(_active_laser_beam):
			_active_laser_beam.activate()

func _on_first_shoot_sound_player_finished() -> void:
	continuous_shoot_sound_player.play()
