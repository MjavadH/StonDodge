class_name Bonus
extends Area2D

signal collected(bonus_type: StringName)

@export var speed: float = 200.0

# --- Node References ---
@onready var sprite: Sprite2D = $Sprite2D
@onready var collection_anim: AnimatedSprite2D = $TakeBonusAnim
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var pickup_bonus_sound: AudioStreamPlayer = $PickupBonusSound

var _bonus_type: StringName

##- Initialization ----------------------------------------------------------##

func initialize(data: BonusData) -> void:
	_bonus_type = data.bonus_type
	sprite.texture = data.texture
	collection_anim.animation = data.collection_anim_name

##- Godot Engine Functions ----------------------------------------------------##

func _physics_process(delta: float) -> void:
	position.y += speed * delta

##- Signal Handlers -----------------------------------------------------------##

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		collected.emit(_bonus_type)
		pickup_bonus_sound.play()
		
		collision_shape.set_deferred("disabled", true)
		speed = 0
		sprite.visible = false
		collection_anim.visible = true
		collection_anim.play()

func _on_take_bonus_anim_animation_finished() -> void:
	queue_free()
