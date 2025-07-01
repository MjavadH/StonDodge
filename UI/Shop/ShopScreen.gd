class_name ShopScreen
extends CanvasLayer

const SHOP_ITEM_SCENE = preload("res://UI/Shop/ShopItem.tscn")
const UPGRADE_ITEM_SCENE = preload("res://UI/Shop/UpgradeItem.tscn")
const HEALTHY_ICON: Texture2D = preload("res://UI/Assets/Healthy.webp")

##- Node References -----------------------------------------------------------##
@onready var score_label: CountingLabel = $ScoreLabel
@onready var bullets_container: Node = $BulletsContainer
@onready var marker_2d: Marker2D = $Panel/Marker2D
@onready var shoot_timer: Timer = $ShootTimer
@onready var shop_item_container: HFlowContainer = $ScrollContainer/ShopItemContainer
@onready var health_bar_container: HBoxContainer = $HealthBarContainer
@onready var upgrade_item_container: HFlowContainer = $UpgradeItemContainer
@onready var ship_container: Node = $ShipContainer

##- Private Variables ---------------------------------------------------------##
var _player_instance: BaseShip 

##- Godot Engine Functions ----------------------------------------------------##
func _ready() -> void:
	get_tree().get_root().connect("go_back_requested", _on_back_button_pressed)
	GameManager.total_score_updated.connect(_on_total_score_updated)
	_update_displays()
	_spawn_player_ship()
	score_label.set_value_instantly(GameManager.get_total_score())

##- Private Functions ---------------------------------------------------------##

func _populate_shop_ships():
	for child in shop_item_container.get_children():
		child.queue_free()
	
	# Get all available ships from the registry and create an item card for each.
	var all_ships = EquipmentRegistry.available_ships
	for ship_data in all_ships:
		var item_instance: ShopItem = SHOP_ITEM_SCENE.instantiate()
		shop_item_container.add_child(item_instance)
		item_instance.configure(ship_data)
		# When any item is bought or equipped, refresh the whole shop.
		item_instance.action_taken.connect(_update_displays)

func _update_displays():
	_on_total_score_updated(GameManager.get_total_score())
	_populate_shop_ships()
	_clear_container(bullets_container)
	_clear_container(ship_container)
	_spawn_player_ship()
	_show_ship_upgrades()

func _clear_container(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()

func _show_ship_upgrades():
	for child in upgrade_item_container.get_children():
		child.queue_free()
	
	var equipped_ship_id = GameManager.get_equipped_ship_id()
	var ship_data: ShipData = EquipmentRegistry.get_ship_data(equipped_ship_id)
	if not ship_data: return

	for upgrade_id in ship_data.available_upgrade_ids:
		var upgrade_data: UpgradeData = UpgradeRegistry.get_upgrade_data(upgrade_id)
		if not upgrade_data: continue
		
		var item_instance: UpgradeItem = UPGRADE_ITEM_SCENE.instantiate()
		upgrade_item_container.add_child(item_instance)
		item_instance.configure(equipped_ship_id, upgrade_data)
		item_instance.upgrade_purchased.connect(_update_displays)

func _setup_health_bar(max_health: int) -> void:
	for child in health_bar_container.get_children():
		child.queue_free()
	
	for i in range(max_health):
		var icon := TextureRect.new()
		icon.texture = HEALTHY_ICON
		health_bar_container.add_child(icon)

func _spawn_player_ship() -> void:
	var ship_id = GameManager.get_equipped_ship_id()
	var ship_data: ShipData = EquipmentRegistry.get_ship_data(ship_id)
	if not ship_data: return
	
	_player_instance = ship_data.ship_scene.instantiate()
	var dependencies = {
		"bullet_container": bullets_container,
		"ship_id": ship_id
	}
	
	ship_container.add_child(_player_instance)
	_player_instance.position = marker_2d.global_position
	_player_instance.initialize(dependencies)
	_player_instance.set_paused(true)
	_setup_health_bar(_player_instance.max_health)
	shoot_timer.wait_time = _player_instance._base_shoot_cooldown
	shoot_timer.start()

func _on_total_score_updated(new_total: int):
	score_label.count_to(new_total)

func _on_shoot_timer_timeout() -> void:
	_player_instance._fire_weapon()

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://UI/StartMenu/start.tscn")
