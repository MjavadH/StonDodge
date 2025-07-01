# UpgradeItem.gd
# A reusable UI component for a single upgrade button in the shop.
# It displays the upgrade's info and handles the purchase logic.
class_name UpgradeItem
extends Button

signal upgrade_purchased # To notify the main shop screen to refresh.

@onready var icon_texture: TextureRect = $Icon
@onready var label: Label = $Label

var _ship_id: StringName
var _upgrade_data: UpgradeData

# This function is called from the ShopScreen to configure the button.
func configure(ship_id: StringName, upgrade_data: UpgradeData):
	_ship_id = ship_id
	_upgrade_data = upgrade_data
	
	icon_texture.texture = _upgrade_data.icon 
	update_display()

func update_display():
	var current_level = GameManager.get_upgrade_level(_ship_id, _upgrade_data.id)
	
	if current_level >= _upgrade_data.max_level:
		label.text = tr("Max Level")
		self.disabled = true
	else:
		var cost = _upgrade_data.cost_per_level[current_level]
		label.text = str(cost)
		self.disabled = GameManager.get_total_score() < cost

func _on_pressed():
	var success = GameManager.purchase_upgrade(_ship_id, _upgrade_data.id)
	if success:
		upgrade_purchased.emit()
