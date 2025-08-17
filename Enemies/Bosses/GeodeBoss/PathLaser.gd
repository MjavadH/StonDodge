class_name PathLaser
extends Node2D

@export var width: float = 50.0
@export var damage: int = 1 # Damage to the player on hit.

@onready var mesh_instance: MeshInstance2D = $MeshInstance2D
@onready var damage_timer: Timer = $DamageTimer

var _points: PackedVector2Array

func fire(path_points: PackedVector2Array, reveal_duration: float, hold_duration: float, retract_duration: float) -> void:
	if path_points.size() < 2:
		queue_free()
		return
	_points = path_points
	var new_mesh = _create_strip_mesh(_points, width)
	mesh_instance.mesh = new_mesh
	
	global_position = Vector2.ZERO
	
	var _material: ShaderMaterial = mesh_instance.material
	_material.set_shader_parameter("heat_progress", 0.0)
	_material.set_shader_parameter("progress", 0.0)

	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_property(_material, "shader_parameter/progress", 1.0, reveal_duration)
	tween.tween_property(_material, "shader_parameter/heat_progress", 0.9, 0.2)
	tween.tween_callback(damage_timer.start)
	tween.tween_interval(hold_duration)
	
	tween.tween_property(_material, "shader_parameter/progress", 0.0, retract_duration)
	
	tween.tween_callback(queue_free)

func _create_strip_mesh(path_points: PackedVector2Array, strip_width: float) -> ArrayMesh:
	var vertices = PackedVector2Array()
	var uvs = PackedVector2Array()
	var indices = PackedInt32Array()
	
	var total_length = 0.0
	for i in range(path_points.size() - 1):
		total_length += path_points[i].distance_to(path_points[i+1])
		
	if total_length == 0.0: return ArrayMesh.new()

	var distance_so_far = 0.0
	for i in range(path_points.size()):
		var current_point = to_local(path_points[i])
		var normal = Vector2.ZERO
		
		if i == 0:
			normal = (to_local(path_points[i+1]) - current_point).orthogonal().normalized()
		elif i == path_points.size() - 1:
			normal = (current_point - to_local(path_points[i-1])).orthogonal().normalized()
		else:
			var dir1 = (current_point - to_local(path_points[i-1])).normalized()
			var dir2 = (to_local(path_points[i+1]) - current_point).normalized()
			normal = (dir1.orthogonal() + dir2.orthogonal()).normalized()
		
		vertices.append(current_point + normal * strip_width / 2.0)
		vertices.append(current_point - normal * strip_width / 2.0)
		
		var v = distance_so_far / total_length
		uvs.append(Vector2(0.0, v))
		uvs.append(Vector2(1.0, v))
		
		if i < path_points.size() - 1:
			distance_so_far += path_points[i].distance_to(path_points[i+1])
		
		if i < path_points.size() - 1:
			var base_index = i * 2
			indices.append_array([base_index, base_index + 1, base_index + 2])
			indices.append_array([base_index + 1, base_index + 3, base_index + 2])

	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	
	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func _check_for_collision() -> void:
	var space_state = get_world_2d().direct_space_state
	
	var query = PhysicsShapeQueryParameters2D.new()
	query.collision_mask = 1 
	
	for i in range(_points.size() - 1):
		var p1 = _points[i]
		var p2 = _points[i+1]
		
		var segment_shape = RectangleShape2D.new()
		var segment_length = p1.distance_to(p2)
		segment_shape.size = Vector2(segment_length, width)
		
		var _transform = Transform2D(p1.direction_to(p2).angle(), (p1 + p2) / 2.0)
		query.transform = _transform
		query.shape = segment_shape
		
		var results = space_state.intersect_shape(query)
		
		if not results.is_empty():
			for result in results:
				var collider = result.collider
				if collider.is_in_group("Player") and collider.has_method("take_damage"):
					collider.take_damage(damage)
					return
