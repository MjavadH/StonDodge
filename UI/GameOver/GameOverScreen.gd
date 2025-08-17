extends CanvasLayer

@onready var game_over_label: Label = $GameOverLabel
@onready var round_score_label: CountingLabel = $Panel/VBoxContainer/RoundScoreLabel
@onready var high_score_label: CountingLabel = $Panel/VBoxContainer/HighScoreLabel
@onready var total_score_label: CountingLabel = $Panel/VBoxContainer/TotalScoreLabel

func _ready() -> void:
	MusicPlayer.change_music(MusicPlayer.MusicType.BACKGROUND)
	GameManager.finalize_run()
	var score = GameManager.get_current_score()
	game_over_label.text = tr("Game Over")
	round_score_label.prefix = tr("Round Score") + ": "
	high_score_label.prefix = tr("High Score") + ": "
	total_score_label.prefix = tr("Total Score") + ": "
	round_score_label.count_to(score)
	high_score_label.count_to(GameManager.get_high_score())
	total_score_label.set_value_instantly(GameManager.get_total_score())

func _on_restart_button_pressed() -> void:
	get_tree().change_scene_to_file("res://World/main.tscn")

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://UI/StartMenu/start.tscn")
