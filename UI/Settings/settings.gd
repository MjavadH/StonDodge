extends CanvasLayer

@onready var settings_label: Label = $Settings_Label
@onready var music_button: CheckButton = $VBoxContainer/MusicButton
@onready var language_button: OptionButton = $VBoxContainer/HBoxContainer/LanguageButton

var setting: Dictionary

func _ready() -> void:
	get_tree().get_root().connect("go_back_requested", _on_back_button_pressed)
	setting = GameManager.get_settings()
	music_button.button_pressed = setting["Music"]
	
	match setting["Language"]:
		"fa": language_button.select(0)
		"en": language_button.select(1)

func _on_back_button_pressed() -> void:
	self.hide()

func _on_check_button_toggled(toggled_on: bool) -> void:
	if setting["Music"] != toggled_on:
		MusicPlayer.set_music_enabled(toggled_on)
		setting["Music"] = toggled_on
		GameManager.update_settings(setting)

func _on_language_button_item_selected(index: int) -> void:
	match index:
		0:
			setting["Language"] = "fa"
		1:
			setting["Language"] = "en"
	TranslationServer.set_locale(setting["Language"])
	GameManager.update_settings(setting)
