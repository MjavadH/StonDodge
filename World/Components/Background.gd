class_name Background
extends CanvasLayer

##- Export Variables ----------------------------------------------------------##
@export var show_drop_effect: bool = true
@export var show_star_effect: bool = true

##- Node References -----------------------------------------------------------##
@onready var drop_node: ColorRect = $Drop
@onready var stars_node: ColorRect = $Stars

var _drop_material: ShaderMaterial
var _stars_material: ShaderMaterial
var _original_drop_color: Color = Color.WHITE

##- Godot Engine Functions ----------------------------------------------------##
func _ready() -> void:
	if drop_node.material is ShaderMaterial:
		_drop_material = drop_node.material
	if stars_node.material is ShaderMaterial:
		_stars_material = stars_node.material

	GameManager.quality_level_changed.connect(_configure_for_quality)
	_configure_for_quality(GameManager.current_quality_level)
	flash_drop_color()

##- Public API ----------------------------------------------------------------##

func flash_drop_color(flash_color: Color = _original_drop_color) -> void:
	if not _drop_material:
		return
	_drop_material.set_shader_parameter("color", flash_color)

##- Private Functions ---------------------------------------------------------##

func _configure_for_quality(new_level: GameManager.QualityLevel) -> void:
	if show_drop_effect and _drop_material:
		drop_node.visible = true
		match new_level:
			GameManager.QualityLevel.LOW:
				_drop_material.set_shader_parameter("high_quality", false)
				_drop_material.set_shader_parameter("density", 50.0)
			GameManager.QualityLevel.MEDIUM:
				_drop_material.set_shader_parameter("high_quality", true)
				_drop_material.set_shader_parameter("density", 100.0)
			GameManager.QualityLevel.HIGH:
				_drop_material.set_shader_parameter("high_quality", true)
				_drop_material.set_shader_parameter("density", 145.0)
	else:
		drop_node.visible = false

	if show_star_effect and _stars_material:
		stars_node.visible = (new_level != GameManager.QualityLevel.LOW)
	else:
		stars_node.visible = false
