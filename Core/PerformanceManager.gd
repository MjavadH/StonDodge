extends Node

const SAMPLE_FRAMES = 200

var _frame_count: int = 0

func _ready() -> void:
	if GameManager.is_quality_level_set():
		set_process(false)
		return

func _process(_delta: float) -> void:
	if _frame_count < SAMPLE_FRAMES:
		_frame_count += 1
		return
	
	var average_fps = Performance.get_monitor(Performance.TIME_FPS)
	if average_fps < 35:
		GameManager.set_quality_level(GameManager.QualityLevel.LOW)
	elif average_fps < 55:
		GameManager.set_quality_level(GameManager.QualityLevel.MEDIUM)
	else:
		GameManager.set_quality_level(GameManager.QualityLevel.HIGH)
	GameManager.save_game()
	set_process(false)
