extends CanvasLayer

@export var character_node: CharacterBody2D

@onready var round_score_label: CountingLabel = $VBoxContainer/RoundScoreLabel
@onready var high_score_label: CountingLabel = $VBoxContainer/HighScoreLabel
@onready var total_score_label: CountingLabel = $VBoxContainer/TotalScoreLabel

func _ready():
	visible = false

func _pauseGame() -> void:
	visible = true
	character_node.set_paused(true)
	Engine.time_scale = 0.0
	GameManager.finalize_run()
	var score = GameManager.get_current_score()
	round_score_label.prefix = tr("Round Score") + ": "
	high_score_label.prefix = tr("High Score") + ": "
	total_score_label.prefix = tr("Total Score") + ": "
	round_score_label.set_value_instantly(score)
	high_score_label.set_value_instantly(GameManager.get_high_score())
	total_score_label.set_value_instantly(GameManager.get_total_score())

func _on_continue_button_pressed() -> void:
	Engine.time_scale = 1.0
	visible = false
	character_node.set_paused(false)

func _on_back_button_pressed() -> void:
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file("res://UI/StartMenu/start.tscn")
