class_name ShopItem
extends Panel

signal action_taken

##- Node References -----------------------------------------------------------##
@onready var icon: TextureRect = $Icon
@onready var name_label: Label = $NameLabel
@onready var action_button: Button = $ActionButton

var _ship_data: ShipData
##- Public Functions ----------------------------------------------------------##

# The main function to set up this item card from the main shop screen.
func configure(data: ShipData):
	_ship_data = data
	
	icon.texture = _ship_data.icon
	name_label.text = _ship_data.ship_name
	
	_update_button_state()

func _update_button_state():
	if not GameManager.is_ship_owned(_ship_data.id):
		action_button.text = str(_ship_data.cost)
		action_button.disabled = GameManager.get_total_score() < _ship_data.cost
	elif GameManager.get_equipped_ship_id() == _ship_data.id:
		action_button.text = tr("Equipped")
		action_button.disabled = true
	else:
		action_button.text = tr("Equip")
		action_button.disabled = false

##- Signal Handlers -----------------------------------------------------------##

func _on_action_button_pressed():
	if not GameManager.is_ship_owned(_ship_data.id):
		var success = GameManager.purchase_ship(_ship_data.id)
		
	else:
		GameManager.equip_ship(_ship_data.id)
		
	# Update its own button state and tell the parent to refresh all other items.
	_update_button_state()
	action_taken.emit()
