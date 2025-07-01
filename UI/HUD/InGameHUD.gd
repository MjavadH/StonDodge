class_name InGameHUD
extends CanvasLayer

# Preload textures for the health icons for optimal performance.
const HEALTHY_ICON: Texture2D = preload("res://UI/Assets/Healthy.webp")
const BROKEN_ICON: Texture2D = preload("res://UI/Assets/Broken.webp")

##- Node References -----------------------------------------------------------##
@onready var health_bar_container: HBoxContainer = $HealthBarContainer
@onready var score_label: CountingLabel = $ScoreLabel
@onready var multiplier_label: Label = $ScoreLabel/MultiplierLabel

##- Public API ----------------------------------------------------------------##

func track_player(player_node: BaseShip) -> void:
	player_node.health_updated.connect(_on_health_updated)
	
	_setup_health_bar(player_node.max_health)
	_on_health_updated(player_node.health, player_node.max_health)

##- Private Functions ---------------------------------------------------------##

func _ready() -> void:
	GameManager.current_score_updated.connect(_on_score_updated)
	GameManager.score_multiplier_changed.connect(_on_score_multiplier_changed)
	_on_score_multiplier_changed(1)
	# Display the initial score.
	score_label.set_value_instantly(0)

func _setup_health_bar(max_health: int) -> void:
	for child in health_bar_container.get_children():
		child.queue_free()
	
	for i in range(max_health):
		var icon := TextureRect.new()
		icon.texture = HEALTHY_ICON
		health_bar_container.add_child(icon)

##- Signal Handlers -----------------------------------------------------------##

func _on_health_updated(current_health: int, _max_health: int) -> void:
	var icons = health_bar_container.get_children()
	for i in range(icons.size()):
		var icon: TextureRect = icons[i]
		if i < current_health:
			icon.texture = HEALTHY_ICON
		else:
			icon.texture = BROKEN_ICON

func _on_score_updated(new_score: int) -> void:
	score_label.count_to(new_score)

func _on_score_multiplier_changed(new_multiplier: int) -> void:
	if new_multiplier > 1:
		multiplier_label.text = "%dx" % new_multiplier
		multiplier_label.show()
	else:
		# If the multiplier is 1 (normal), hide the label.
		multiplier_label.hide()
