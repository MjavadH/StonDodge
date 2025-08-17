class_name AbilityButton
extends Panel

##- Node References -----------------------------------------------------------##
@onready var input_catcher: TouchScreenButton = $InputCatcher
@onready var texture_rect: TextureRect = $MarginContainer/TextureRect
@onready var shader_material: ShaderMaterial = texture_rect.material

##- Private State -------------------------------------------------------------##
var _player_ship: BaseShip
var _ability_data: AbilityData
var _touch_shape: Shape2D

##- Public API ----------------------------------------------------------------##
func configure(player: BaseShip, ability_data: AbilityData) -> void:
	_player_ship = player
	_ability_data = ability_data
	
	if texture_rect.material:
		texture_rect.material = texture_rect.material.duplicate()
	shader_material = texture_rect.material
	
	texture_rect.texture = _ability_data.icon
	
	_player_ship.ability_activated.connect(_on_ability_activated)
	_player_ship.ability_ready.connect(_on_ability_ready)
	
	_on_resized()
	_on_ability_ready(_ability_data.id)

##- Signal Handlers & Logic ---------------------------------------------------##

func _on_input_catcher_pressed() -> void:
	if is_instance_valid(_player_ship):
		_player_ship.try_activate_ability(_ability_data.id)

func _on_resized() -> void:
	var current_size: Vector2 = self.size
	var new_shape: RectangleShape2D = RectangleShape2D.new()
	new_shape.size = current_size
	_touch_shape = new_shape
	
	# Apply the shape to the button.
	input_catcher.shape = _touch_shape
	input_catcher.position = current_size / 2.0

func _on_ability_activated(ability_id: StringName) -> void:
	if ability_id != _ability_data.id: return
	
	input_catcher.shape = null
	
	var tween: Tween = create_tween()
	tween.tween_property(shader_material, "shader_parameter/progress", 1.0, _ability_data.cooldown_duration)\
		 .from(0.0)\
		 .set_trans(Tween.TRANS_LINEAR)

func _on_ability_ready(ability_id: StringName) -> void:
	if ability_id != _ability_data.id: return
		
	if is_instance_valid(_touch_shape):
		input_catcher.shape = _touch_shape
	
	if shader_material:
		shader_material.set_shader_parameter("progress", 1.0)
