class_name DamageArea
extends Area2D

##- Signals -------------------------------------------------------------------##
signal player_hit

##- Export Variables ----------------------------------------------------------##
@export var damage_amount: int = 2
@export var damage_interval: float = 1.0:
	set(value):
		damage_interval = value
		if damage_timer:
			damage_timer.wait_time = damage_interval

##- Private Variables ---------------------------------------------------------##
var _players_in_area: Array[Node2D] = []

##- Node References -----------------------------------------------------------##
@onready var damage_timer: Timer = $DamageTimer

##- Godot Engine Functions ----------------------------------------------------##
func _ready() -> void:
	damage_timer.wait_time = damage_interval
	damage_timer.one_shot = false

##- Signal Handlers -----------------------------------------------------------##
func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return
		
	if not _players_in_area.has(body):
		_players_in_area.append(body)
		
		_deal_damage_to([body])
		
		if not damage_timer.is_stopped():
			return
		damage_timer.start()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		_players_in_area.erase(body)
		
		if _players_in_area.is_empty():
			damage_timer.stop()

func _on_damage_timer_timeout() -> void:
	if _players_in_area.is_empty():
		return
	
	_deal_damage_to(_players_in_area)

##- Private Functions ---------------------------------------------------------##
func _deal_damage_to(targets: Array[Node2D]) -> void:
	for player in targets:
		if is_instance_valid(player) and player.has_method("take_damage"):
			player.take_damage(damage_amount)
			player_hit.emit()
