extends Node

var music_player := AudioStreamPlayer.new()

func _ready():
	add_child(music_player)
	var setting: Dictionary = GameManager.get_settings()
	var music = load("res://World/Assets/Background.ogg")
	music_player.stream = music
	music_player.volume_db = -15
	music_player.stream.loop = true
	change_state(setting["Music"])

func change_state(play: bool) -> void:
	if play and not music_player.playing:
		music_player.play()
	else:
		music_player.stop()
