extends CanvasLayer

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var game_mode_modal: Panel = $GameModeModal
@onready var settings: CanvasLayer = $Settings
@onready var background: Background = $Background

func _ready() -> void:
	var setting: Dictionary = GameManager.get_settings()
	TranslationServer.set_locale(setting["Language"])
	MusicPlayer.change_music(MusicPlayer.MusicType.BACKGROUND)

func _process(delta: float) -> void:
	$Path2D/PathFollow2D.progress += 200 * delta

func _on_start_button_pressed() -> void:
	if not game_mode_modal.visible:
		animation_player.play("ShowGameModeModal")

func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _on_settings_button_pressed() -> void:
	settings.show()

func _on_shop_button_pressed() -> void:
	get_tree().change_scene_to_file("res://UI/Shop/ShopScreen.tscn")

func _on_classic_button_pressed() -> void:
	GameManager.set_game_mode(GameManager.GameMode.CLASSIC)
	get_tree().change_scene_to_file("res://World/main.tscn")

func _on_survival_button_pressed() -> void:
	GameManager.set_game_mode(GameManager.GameMode.SURVIVAL)
	get_tree().change_scene_to_file("res://World/main.tscn")

func _on_boss_rush_button_pressed() -> void:
	GameManager.set_game_mode(GameManager.GameMode.BOSS_RUSH)
	get_tree().change_scene_to_file("res://World/main.tscn")

func _on_blackout_button_pressed() -> void:
	GameManager.set_game_mode(GameManager.GameMode.BLACKOUT)
	get_tree().change_scene_to_file("res://World/main.tscn")

func _on_payload_escort_button_pressed() -> void:
	GameManager.set_game_mode(GameManager.GameMode.PAYLOAD_ESCORT)
	get_tree().change_scene_to_file("res://World/main.tscn")

func _on_close_modal_button_pressed() -> void:
	animation_player.play("CloseGameModeModal")
