@tool
class_name RollingLabel
extends Control

##- Export Variables ----------------------------------------------------------##
@export var roll_duration: float = 0.1 # Duration for EACH digit to roll.
@export var transition_type: Tween.TransitionType = Tween.TRANS_SINE
@export var ease_type: Tween.EaseType = Tween.EASE_IN_OUT

@export var value: String = "" : set = set_value

##- Private State -------------------------------------------------------------##
var _current_value: int = 0
var _target_value: int = 0
var _is_rolling: bool = false

##- Node References -----------------------------------------------------------##
@onready var current_label: Label = $CurrentLabel
@onready var next_label: Label = $NextLabel

##- Public API ----------------------------------------------------------------##

# Sets the value instantly without any animation.
func set_value_instantly(new_value: int):
	_current_value = new_value
	_target_value = new_value
	current_label.text = str(_current_value)

# Call this function to start the rolling animation to a new number.
func roll_to(new_target: int):
	if new_target == _target_value:
		return
	
	_target_value = new_target
	
	# If a roll is not already in progress, start a new one.
	if not _is_rolling:
		_process_roll_queue()

##- Private Animation Logic ---------------------------------------------------##

func set_value(new_val: String) -> void:
	value = new_val
	
	# در ادیتور: فقط متن رو تغییر بده
	if Engine.is_editor_hint():
		if current_label:
			current_label.text = value
	else:
		# در حالت اجرا: به عدد تبدیل کن و نمایش بده
		var int_val := new_val.to_int()
		roll_to(int_val)

# This is the core function that processes one step of the roll.
func _process_roll_queue():
	# If we have reached the target, stop.
	if _current_value == _target_value:
		_is_rolling = false
		return
	
	_is_rolling = true
	
	# Determine the next number and the direction of the roll.
	var direction = 1 if _target_value > _current_value else -1
	var next_value = _current_value + direction
	
	# 1. Setup the labels for the animation.
	var label_height = self.size.y
	current_label.text = str(_current_value)
	next_label.text = str(next_value)
	
	current_label.position.y = 0
	# Place the next label below (for rolling up) or above (for rolling down).
	next_label.position.y = label_height * direction
	
	# 2. Create and run the tween.
	var tween = create_tween()
	tween.set_parallel() # Animate both labels at the same time.
	
	# Animate the current label moving out.
	tween.tween_property(current_label, "position:y", -label_height * direction, roll_duration)\
		 .set_trans(transition_type).set_ease(ease_type)

	# Animate the next label moving in.
	tween.tween_property(next_label, "position:y", 0, roll_duration)\
		 .set_trans(transition_type).set_ease(ease_type)
	
	# 3. When the tween finishes, update the state and continue the chain.
	await tween.finished
	
	_current_value = next_value
	current_label.text = next_label.text
	current_label.position.y = 0
	
	# Call this function again to process the next number in the sequence.
	_process_roll_queue()
