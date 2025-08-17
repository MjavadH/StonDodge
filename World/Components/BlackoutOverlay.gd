class_name BlackoutOverlay
extends ColorRect

const MAX_LIGHTS = 8

var _light_sources: Array[Dictionary] = []

@onready var _shader_material: ShaderMaterial = material

func _process(_delta: float) -> void:
	var origins = PackedVector2Array()
	var radii = PackedFloat32Array()
	
	var viewport_size = get_viewport_rect().size
	
	for i in range(_light_sources.size() - 1, -1, -1):
		var source = _light_sources[i]
		var node: Node2D = source.node
		
		if is_instance_valid(node):
			origins.append(node.global_position / viewport_size)
			radii.append(source.radius)
		else:
			_light_sources.remove_at(i)
	
	origins.resize(MAX_LIGHTS)
	radii.resize(MAX_LIGHTS)
	
	_shader_material.set_shader_parameter("light_origins", origins)
	_shader_material.set_shader_parameter("light_radii", radii)
	_shader_material.set_shader_parameter("active_light_count", _light_sources.size())
	
##- Public API ----------------------------------------------------------------##

func add_light_source(node: Node2D, radius: float):
	if _light_sources.size() >= MAX_LIGHTS:
		return
		
	for source in _light_sources:
		if source.node == node:
			return
			
	_light_sources.append({
		"node": node,
		"radius": radius
	})

func remove_light_source(node: Node2D):
	for i in range(_light_sources.size() - 1, -1, -1):
		if _light_sources[i].node == node:
			_light_sources.remove_at(i)
			return
