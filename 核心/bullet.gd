extends Area2D

@export var speed: float = 300.0
@export var damage: float = 15.0

var _target: Node2D = null

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	if not _target or not is_instance_valid(_target):
		queue_free()
		return
	var dir := (_target.global_position - global_position).normalized()
	global_position += dir * speed * delta


func initialize(p_target: Node2D, p_damage: float) -> void:
	_target = p_target
	damage = p_damage


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy") and is_instance_valid(_target):
		var enemy = area.get_parent()
		if enemy == _target or enemy.has_method("take_damage"):
			enemy.take_damage(damage)
		queue_free()