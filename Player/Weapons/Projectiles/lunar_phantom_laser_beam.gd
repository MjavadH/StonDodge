class_name LaserBeam
extends Node2D

##- Export Variables ----------------------------------------------------------##
@export var damage_per_tick: int = 2
@export var damage_interval: float = 0.3
@export var max_length: float = 1000.0

##- Private State -------------------------------------------------------------##
var _current_target: Node = null

##- Node References -----------------------------------------------------------##
@onready var visual: ColorRect = $Visual
@onready var damage_timer: Timer = $DamageTimer

##- Godot Engine Functions & Public API ---------------------------------------##
func _ready() -> void:
	# The beam is invisible until activated.
	visual.visible = false
	damage_timer.wait_time = damage_interval

# Called by the ship to turn the laser on.
func activate() -> void:
	visual.visible = true
	damage_timer.start()

# Called by the ship to turn the laser off.
func deactivate() -> void:
	visual.visible = false
	damage_timer.stop()
	_current_target = null

func update_beam(direction: Vector2) -> void:
	var start_point = global_position
	var end_point = start_point - direction.normalized() + Vector2(0,-max_length)
	
	var space_state = get_world_2d().direct_space_state
	var params = PhysicsRayQueryParameters2D.create(start_point, end_point)
	params.collide_with_areas = true
	params.collision_mask = 2 
	
	if get_parent() is Node2D:
		params.exclude = [get_parent().get_rid()]

	var result: Dictionary = space_state.intersect_ray(params)
	
	var beam_length: float

	if result:
		beam_length = global_position.distance_to(result.position)
		_current_target = result.collider
	else:
		beam_length = max_length
		_current_target = null
	
	visual.size.x = lerp(visual.size.x,beam_length + 20,0.3) 

##- Signal Handlers -----------------------------------------------------------##
func _on_damage_timer_timeout() -> void:
	if is_instance_valid(_current_target) and _current_target.is_in_group("Enemy"):
		if _current_target.has_method("take_damage"):
			_current_target.take_damage(damage_per_tick)
