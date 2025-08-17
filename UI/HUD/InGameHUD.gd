class_name InGameHUD
extends CanvasLayer

signal pause_request

const ABILITY_BUTTON_SCENE: PackedScene = preload("res://UI/Components/AbilityButton.tscn")

##- Node References -----------------------------------------------------------##
@onready var ability_button_container: VFlowContainer = $AbilityButtonContainer
@onready var multiplier_label: Label = $Panel/MarginContainer/HFlowContainer/ScorePanel/MultiplierLabel
@onready var score_label: CountingLabel = $Panel/MarginContainer/HFlowContainer/ScorePanel/HFlowContainer/ScoreLabel
@onready var health_label: RollingLabel = $Panel/MarginContainer/HFlowContainer/HealthPanel/HFlowContainer/HealthLabel
@onready var boss_health_bar: ProgressBar = $Panel/MarginContainer/HFlowContainer/BossPanel/HFlowContainer/BossHealthBar
@onready var boss_panel: Panel = $Panel/MarginContainer/HFlowContainer/BossPanel
@onready var panel: Panel = $Panel
@onready var payload_health_label: RollingLabel = $Panel/MarginContainer/HFlowContainer/PayloadHealthPanel/HFlowContainer/PayloadHealthLabel
@onready var payload_health_panel: Panel = $Panel/MarginContainer/HFlowContainer/PayloadHealthPanel

##- Public API ----------------------------------------------------------------##

func track_player(player_node: BaseShip) -> void:
	player_node.health_updated.connect(_on_health_updated)
	_on_health_updated(player_node.health, player_node.max_health)
	_populate_ability_buttons(player_node)

func track_payload(payload_node: Payload) -> void:
	payload_node.health_changed.connect(_on_payload_health_updated)
	_on_payload_health_updated(payload_node.health, payload_node.max_health)
	payload_health_panel.visible = true

##- Godot Engine Functions ----------------------------------------------------##

func _ready() -> void:
	var screen_rect: Rect2 = get_viewport().get_visible_rect()
	GameManager.current_score_updated.connect(_on_score_updated)
	GameManager.score_multiplier_changed.connect(_on_score_multiplier_changed)
	BossManager.boss_spawned.connect(_on_boss_spawned)
	BossManager.boss_defeated.connect(_on_boss_defeated)
	multiplier_label.hide()
	boss_panel.hide()
	_on_score_multiplier_changed(1)
	# Display the initial score.
	score_label.set_value_instantly(0)
	panel.custom_minimum_size.y = screen_rect.size.y * 0.05
	
##- Private Functions ---------------------------------------------------------##

func _populate_ability_buttons(player_node: BaseShip) -> void:
	for child in ability_button_container.get_children():
		child.queue_free()
		
	var ship_data: ShipData = EquipmentRegistry.get_ship_data(player_node.id)
	if not ship_data: return

	for ability_data in ship_data.abilities:
		var button_instance: AbilityButton = ABILITY_BUTTON_SCENE.instantiate()
		
		ability_button_container.add_child(button_instance)
		button_instance.configure(player_node, ability_data)

##- Signal Handlers -----------------------------------------------------------##

func _on_health_updated(current_health: int, _max_health: int) -> void:
	health_label.roll_to(current_health)

func _on_payload_health_updated(current_health: int, _max_health: int) -> void:
	payload_health_label.roll_to(current_health)

func _on_score_updated(new_score: int) -> void:
	score_label.count_to(new_score)

func _on_score_multiplier_changed(new_multiplier: int) -> void:
	if new_multiplier > 1:
		multiplier_label.text = "%dx" % new_multiplier
		multiplier_label.show()
	else:
		# If the multiplier is 1 (normal), hide the label.
		multiplier_label.hide()

func _on_boss_spawned(boss_node):
	boss_health_bar.max_value = boss_node.health
	boss_health_bar.value = boss_node.health
	boss_node.health_changed.connect(_on_boss_health_changed)
	boss_panel.show()

func _on_boss_health_changed(health: int):
	boss_health_bar.value = health

func _on_boss_defeated(_boss_id: StringName, _score_value: int) -> void:
	boss_panel.hide()

func _on_pause_button_pressed() -> void:
	pause_request.emit()
