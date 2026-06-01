extends "res://核心/bullet.gd"

@onready var bolt_sprite: Sprite2D = $Sprite2D

var _anim_timer: float = 0.0
const ANIM_FPS: float = 4.0

func _ready():
	super()
	if bolt_sprite:
		bolt_sprite.hframes = 4

func _process(delta):
	_anim_timer += delta
	if _anim_timer >= 1.0 / ANIM_FPS:
		_anim_timer -= 1.0 / ANIM_FPS
		if bolt_sprite:
			bolt_sprite.frame = (bolt_sprite.frame + 1) % 4

# 命中：伤害 + 爆炸特效
func _hit():
	if is_instance_valid(target) and target.has_method("take_damage"):
		target.take_damage(damage)
	_spawn_explosion()
	queue_free()

func _on_area_entered(area):
	if area.is_in_group("enemy"):
		var enemy = area.get_parent()
		if enemy.has_method("take_damage"):
			enemy.take_damage(damage)
		_spawn_explosion()
		queue_free()

func _spawn_explosion():
	var explosion = preload("res://核心/magic_explosion.tscn").instantiate()
	explosion.global_position = global_position
	get_parent().add_child(explosion)
