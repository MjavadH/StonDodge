class_name BurnEffect
extends Node

@export var damage_per_tick: int = 2
@export var tick_interval: float = 1.0
@export var duration: float = 3.0

@onready var damage_tick_timer: Timer = $DamageTickTimer
@onready var duration_timer: Timer = $DurationTimer

var _target: Node

func _ready() -> void:
	_target = get_parent()
	
	damage_tick_timer.wait_time = tick_interval
	duration_timer.wait_time = duration
	
	damage_tick_timer.start()
	duration_timer.start()
	
	damage_tick_timer.timeout.connect(_on_damage_tick)
	duration_timer.timeout.connect(queue_free)
	_on_damage_tick()

func _on_damage_tick():
	if is_instance_valid(_target) and not _target.get("_is_dead"):
		if _target.has_method("take_damage"):
			_target.take_damage(damage_per_tick)
