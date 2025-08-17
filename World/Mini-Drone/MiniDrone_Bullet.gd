extends Area2D

const SPEED: int = 1200

func _process(delta: float) -> void:
	var direction = Vector2.RIGHT.rotated(rotation)
	self.position += direction * SPEED * delta

func _handle_hit(target: Node) -> void:
	if target.is_in_group("Enemy") and not target.get("_is_dead"):
		if target.has_method("take_damage"):
			target.take_damage(1)
			queue_free()

##- Signal Handlers -----------------------------------------------------------##

func _on_area_entered(area: Area2D) -> void:
	_handle_hit(area)

func _on_body_entered(body: Node2D) -> void:
	_handle_hit(body)
