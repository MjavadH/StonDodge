@tool
class_name CountingLabel
extends Label

##- Export Variables ----------------------------------------------------------##
# Configures the animation of the number.
@export var duration: float = 0.8
@export var transition_type: Tween.TransitionType = Tween.TRANS_SINE
@export var ease_type: Tween.EaseType = Tween.EASE_OUT

# Configures the text format.
@export var prefix: String = ""
@export var suffix: String = ""

##- Private Variables ---------------------------------------------------------##
var _current_value: float = 0.0:
	set(new_value):
		_current_value = new_value
		text = "%s%d%s" % [prefix, roundi(_current_value), suffix]

var _tween: Tween

##- Godot Engine Functions ----------------------------------------------------##
func _ready() -> void:
	_current_value = _current_value

##- Public API ----------------------------------------------------------------##
func count_to(new_target: int) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "_current_value", float(new_target), duration)\
		  .set_trans(transition_type)\
		  .set_ease(ease_type)

func set_value_instantly(new_value: int) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	self._current_value = float(new_value)
