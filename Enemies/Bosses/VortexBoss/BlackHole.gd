class_name BlackHole
extends Area2D



func _ready() -> void:
	scale = Vector2.ZERO
	monitoring = false
	
	var target_scale_value = randf_range(0.4, 0.8)
	var target_scale = Vector2.ONE * target_scale_value
	
	var tween = create_tween()
	tween.set_parallel(false)
	
	
	tween.tween_property(self, "scale", target_scale, 1.0)\
		 .set_trans(Tween.TRANS_QUINT)\
		 .set_ease(Tween.EASE_OUT)
		 
	tween.tween_callback(func(): self.monitoring = true)
	
	tween.tween_interval(2.0)
	
	tween.tween_property(self, "scale", Vector2.ZERO, 1.0)\
		 .set_trans(Tween.TRANS_QUINT)\
		 .set_ease(Tween.EASE_IN)
		 
	tween.tween_callback(queue_free)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") and !body._is_dead:
		if body.has_method("take_damage"):
			body.take_damage(1)
