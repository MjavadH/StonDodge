extends Area2D

@export var speed := 200
@export var BonusTypes = ""

@onready var take_bonus_anim: AnimatedSprite2D = $TakeBonusAnim
@onready var sprite: Sprite2D = $Sprite2D

var bonus_types = [
	{ "type": "Heal", "Anim": "Red" },
	{ "type": "Speed", "Anim": "Blue"},
	{ "type": "BulletSpeed", "Anim": "Orange"},
	{ "type": "2x", "Anim": "Orange"}
]

func setup(type: Dictionary):
	BonusTypes = type
	var sprite_node = get_node("Sprite2D")
	match type["type"]:
		"Heal":
			sprite_node.texture = load("res://Bonus/assets/Bonus_Heal.webp")
		"Speed":
			sprite_node.texture = load("res://Bonus/assets/Bonus_Speed.webp")
		"BulletSpeed":
			sprite_node.texture = load("res://Bonus/assets/Bonus_BulletSpeed.webp")
		"2x":
			sprite_node.texture = load("res://Bonus/assets/Bonus_2x.webp")

func _physics_process(delta):
	position.y += speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		body.apply_bonus(BonusTypes["type"])
		sprite.visible = false
		take_bonus_anim.visible = true
		take_bonus_anim.play(BonusTypes["Anim"])

func _on_take_bonus_anim_animation_finished() -> void:
		queue_free()
