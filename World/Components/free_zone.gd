extends Area2D

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("Enemy") or area.is_in_group("Bullet"):
		area.queue_free()
	
