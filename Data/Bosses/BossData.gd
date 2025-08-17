class_name BossData
extends Resource

@export_group("Core Info")
@export var id: StringName
@export var boss_scene: PackedScene
@export var score_on_defeat: int = 100

@export_group("Combat Stats")
@export var initial_health: int = 100
@export var projectile_scene: PackedScene
