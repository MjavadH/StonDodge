class_name UpgradeItem
extends Button

signal upgrade_purchased

@onready var icon_texture: TextureRect = $MarginContainer/VBoxContainer/Icon
@onready var failed_action_sound: AudioStreamPlayer = $FailedActionSound
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var cost_label: Label = $CostLabel
@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleLabel

var _ship_id: StringName
var _upgrade_data: UpgradeData

func configure(ship_id: StringName, upgrade_data: UpgradeData) -> void:
	_ship_id = ship_id
	_upgrade_data = upgrade_data
	
	icon_texture.texture = _upgrade_data.icon 
	update_display()

func update_display() -> void:
	var current_level = GameManager.get_upgrade_level(_ship_id, _upgrade_data.id)
	
	title_label.text = tr(_upgrade_data.title)
	
	if current_level >= _upgrade_data.max_level:
		cost_label.text = tr("Max Level")
	else:
		var cost: int = _upgrade_data.cost_per_level[current_level]
		cost_label.text = str(cost)

func _on_pressed() -> void:
	var success: bool = GameManager.purchase_upgrade(_ship_id, _upgrade_data.id)
	if success:
		upgrade_purchased.emit()
	else:
		animation_player.play("failed")
		failed_action_sound.play()
