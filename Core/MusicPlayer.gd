extends Node

##- Enums & Constants ---------------------------------------------------------##
enum MusicType { BACKGROUND, BOSS }

const BACKGROUND_MUSIC: AudioStream = preload("res://World/Assets/Background.ogg")
const BOSS_MUSIC: AudioStream = preload("res://World/Assets/BOSS.ogg")

##- Export Variables ----------------------------------------------------------##
@export var fade_duration: float = 2.0 # Duration of the cross-fade in seconds.

##- Private Variables ---------------------------------------------------------##
var _active_player: AudioStreamPlayer
var _inactive_player: AudioStreamPlayer
var _current_music_type: MusicType = MusicType.BACKGROUND
var _is_enabled: bool = true
var _crossfade_tween: Tween

##- Node References -----------------------------------------------------------##
@onready var _player_a: AudioStreamPlayer = $MusicPlayerA
@onready var _player_b: AudioStreamPlayer = $MusicPlayerB

##- Godot Engine Functions ----------------------------------------------------##
func _ready() -> void:
	
	# Set initial player roles.
	_active_player = _player_a
	_inactive_player = _player_b
	
	# Set initial music and state based on saved settings.
	var settings: Dictionary = GameManager.get_settings()
	_is_enabled = settings.get("Music", true)
	
	_active_player.stream = BACKGROUND_MUSIC
	_active_player.stream.loop = true
	if _is_enabled:
		_active_player.play()
	else:
		set_music_enabled(false)
	
##- Public API ----------------------------------------------------------------##

func change_music(new_music_type: MusicType) -> void:
	if new_music_type == _current_music_type:
		return

	_current_music_type = new_music_type
	var new_stream: AudioStream = BOSS_MUSIC if new_music_type == MusicType.BOSS else BACKGROUND_MUSIC
	
	# Stop any previous cross-fade animation.
	if _crossfade_tween and _crossfade_tween.is_valid():
		_crossfade_tween.kill()

	_inactive_player.stream = new_stream
	_inactive_player.stream.loop = true
	if _is_enabled:
		_inactive_player.play()
	
	_crossfade_tween = create_tween()
	_crossfade_tween.set_parallel(true) # Animate both properties at the same time.
	
	# Fade out the active player.
	_crossfade_tween.tween_property(_active_player, "volume_db", -80.0, fade_duration)
	
	# Fade in the inactive player.
	_crossfade_tween.tween_property(_inactive_player, "volume_db", 0.0, fade_duration).from(-80.0)
	
	# After the fade, clean up and swap the players.
	_crossfade_tween.finished.connect(func() -> void:
		_active_player.stop()
		var temp: AudioStreamPlayer = _active_player
		_active_player = _inactive_player
		_inactive_player = temp
	)

func set_music_enabled(is_enabled: bool) -> void:
	_is_enabled = is_enabled
	AudioServer.set_bus_mute(0, not is_enabled)
	
	if is_enabled and not _active_player.playing:
		_active_player.play()
	elif not is_enabled:
		_active_player.stop()
