extends Camera2D

var shake_amount: float = 0.0
var shake_decay: float = 5.0
var original_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	original_offset = offset
	set_process(false)

func _process(delta: float) -> void:
	if shake_amount > 0:
		offset = original_offset + Vector2(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		) * shake_amount
		shake_amount = max(shake_amount - shake_decay * delta, 0)
	else:
		offset = original_offset

func start_shake(amount: float = 10.0) -> void:
	shake_amount = amount
	set_process(true)
