extends CanvasLayer

func _ready() -> void:
	var setting = GameManager.get_settings()
	TranslationServer.set_locale(setting["Language"])

func _process(delta: float) -> void:
	$Path2D/PathFollow2D.progress += 200 * delta

func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://World/main.tscn")

func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _on_settings_button_pressed() -> void:
	$Settings.ShowSetting()

func _on_shop_button_pressed() -> void:
	get_tree().change_scene_to_file("res://UI/Shop/ShopScreen.tscn")
