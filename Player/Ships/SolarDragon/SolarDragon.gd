extends BaseShip

##- Constants -----------------------------------------------------------------##
const BULLET_SCENE: PackedScene = preload("res://Player/Ships/SolarDragon/Weapons/SolarPulse/SolarPulse.tscn")
const SHOOT_SOUND: AudioStream = preload("res://Player/Ships/SolarDragon/Weapons/SolarPulse/assets/Charge.ogg")
const BURN_EFFECT_SCENE = preload("res://Player/Ships/SolarDragon/Abilities/SolarFlare/BurnEffect.tscn")

@export_group("Photon Dash")
@export var dash_speed: float = 3000.0
@export var dash_duration: float = 0.3
@export var dash_damage: int = 10 # High damage to destroy most enemies instantly

##- State Machine -------------------------------------------------------------##
enum State { NORMAL, DASHING }
var _current_state = State.NORMAL

##- Private Variables ---------------------------------------------------------##
var power_orbit: float = 100.0
var charge_speed_scale: float = 1.0
var explosive_power: int = 1

##- Node References -----------------------------------------------------------##
@onready var dash_timer: Timer = $DashTimer
@onready var dash_hitbox: Area2D = $DashHitbox
@onready var solar_flare_radius: Area2D = $SolarFlareRadius
@onready var solar_flare_visual: ColorRect = $SolarFlareRadius/SolarFlareVisual
@onready var solar_flare_timer: Timer = $SolarFlareTimer
@onready var solar_flare_tick_timer: Timer = $SolarFlareTickTimer
@onready var solar_flare_sound: AudioStreamPlayer = $SolarFlareSound
@onready var dash_sound: AudioStreamPlayer = $DashSound

##- Godot Engine Functions ----------------------------------------------------##

func _physics_process(delta: float):
	match _current_state:
		State.NORMAL:
			super._physics_process(delta)
		State.DASHING:
			move_and_slide()

##- "Virtual" Methods ---------------------------------------------------------##

func _initialize_stats() -> void:
	super._initialize_stats()
	max_health = 10
	speed = 1200.0
	shoot_timer.wait_time = 0.5
	_base_speed = speed
	_base_shoot_cooldown = shoot_timer.wait_time
	dash_timer.wait_time = dash_duration

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
	match ability_id:
		&"photon_dash":
			if _current_state == State.NORMAL:
				_is_invincible = true
				_current_state = State.DASHING
				dash_hitbox.monitoring = true
				velocity = Vector2.UP * dash_speed
				dash_sound.play()
				dash_timer.start()
		&"solar_flare":
			solar_flare_sound.play()
			solar_flare_radius.monitoring = true
			solar_flare_visual.show()
			solar_flare_timer.start()
			solar_flare_tick_timer.start()
			
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

func _on_dash_timer_timeout() -> void:
	_current_state = State.NORMAL
	dash_hitbox.monitoring = false
	self.self_modulate = Color.from_rgba8(255,200,0,128)
	await get_tree().create_timer(1.5).timeout
	_is_invincible = false
	self.self_modulate = Color.WHITE

func _on_dash_hitbox_entered(target: Node2D):
	if target.is_in_group("Enemy") and target.has_method("take_damage"):
		target.take_damage(dash_damage)
		if target.is_in_group("Boss"):
			_current_state = State.NORMAL

func _on_solar_flare_tick_timer_timeout() -> void:
	var targets = solar_flare_radius.get_overlapping_areas() + solar_flare_radius.get_overlapping_bodies()
	for target in targets:
		if target.is_in_group("Enemy"):
			if not target.find_child("BurnEffect", false):
				var burn_effect = BURN_EFFECT_SCENE.instantiate()
				target.add_child(burn_effect)

func _on_solar_flare_timer_timeout() -> void:
	solar_flare_tick_timer.stop()
	solar_flare_radius.set_deferred("monitoring",false)
	solar_flare_visual.hide()
