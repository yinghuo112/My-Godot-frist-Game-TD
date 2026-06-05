extends "res://子弹/bullet.gd"

const _MAGIC_EXPLOSION = preload("res://子弹/magic_explosion.tscn")

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
	if _has_hit:
		return
	_has_hit = true
	_spawn_explosion()
	_apply_damage(target)
	call_deferred("_release")

func _on_area_entered(area):
	if _has_hit:
		return
	if area.is_in_group("enemy"):
		_has_hit = true
		_spawn_explosion()
		_apply_damage(area.get_parent())
		call_deferred("_release")

func _spawn_explosion():
	var explosion = _MAGIC_EXPLOSION.instantiate()
	explosion.global_position = global_position
	get_parent().add_child(explosion)
