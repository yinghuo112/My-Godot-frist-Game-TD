extends "res://子弹/bullet.gd"

@onready var bolt_sprite: Sprite2D = $Sprite2D

var _anim_timer: float = 0.0
const ANIM_FPS: float = 6.0

func _ready():
	super()
	if bolt_sprite:
		bolt_sprite.hframes = 6

func _process(delta):
	_anim_timer += delta
	if _anim_timer >= 1.0 / ANIM_FPS:
		_anim_timer -= 1.0 / ANIM_FPS
		if bolt_sprite:
			bolt_sprite.frame = (bolt_sprite.frame + 1) % 6

func _hit():
	if _has_hit:
		return
	_has_hit = true
	_spawn_effects()
	_apply_damage(target)
	call_deferred("_release")

func _on_area_entered(area):
	if _has_hit:
		return
	if area.is_in_group("enemy"):
		_has_hit = true
		_spawn_effects()
		_apply_damage(area.get_parent())
		call_deferred("_release")

func _spawn_effects():
	var explosion = preload("res://子弹/mage_explosion.tscn").instantiate()
	explosion.global_position = global_position
	get_parent().add_child(explosion)
	var sparkle = preload("res://子弹/mage_sparkle.tscn").instantiate()
	sparkle.global_position = global_position
	get_parent().add_child(sparkle)
