# ===== 火球子弹 =====
# 圆形火球(逐帧重绘) + 拖尾粒子 + 命中爆炸溅射
extends "res://子弹/bullet.gd"

const _FIRE_EXPLOSION = preload("res://子弹/fireball_explosion.tscn")

@export var splash_radius: float = 60.0
@export var splash_damage_ratio: float = 0.5

@onready var _trail: GPUParticles2D = $GPUParticles2D
@onready var _sprite: Sprite2D = $Sprite2D

var _pulse: float = 0.0
var _splash_shape: CircleShape2D

func _ready():
	super()
	_splash_shape = CircleShape2D.new()
	_splash_shape.radius = splash_radius
	if _trail:
		_trail.emitting = true

func _process(delta):
	_pulse += delta
	_sprite.frame = int(_pulse * 10) % 12
	queue_redraw()

func _draw():
	draw_circle(Vector2.ZERO, 6, Color(1, 0.9, 0.4, 0.5))
	draw_circle(Vector2.ZERO, 9, Color(1, 0.5, 0.0, 0.35))
	var outer = 13.0 + sin(_pulse * 8.0) * 2.0
	draw_circle(Vector2.ZERO, outer, Color(1, 0.2, 0.0, 0.15))

func _hit():
	if _has_hit:
		return
	_has_hit = true
	_spawn_explosion()
	AudioManager.play("fireball")
	_apply_damage(target)
	_splash_damage(target, global_position)
	call_deferred("_release")

func _on_area_entered(area):
	if _has_hit:
		return
	if area.is_in_group("enemy"):
		_has_hit = true
		var enemy = area.get_parent()
		_spawn_explosion()
		AudioManager.play("fireball")
		_apply_damage(enemy)
		_splash_damage(enemy, global_position)
		call_deferred("_release")

func _spawn_explosion():
	var explosion = _FIRE_EXPLOSION.instantiate()
	explosion.global_position = global_position
	get_parent().add_child(explosion)

func _splash_damage(hit_enemy: Node2D, pos: Vector2):
	var space = get_world_2d().direct_space_state
	if not space:
		return
	var query = PhysicsShapeQueryParameters2D.new()
	query.set_shape(_splash_shape)
	query.transform = Transform2D(0, pos)
	query.collision_mask = 2
	var results = space.intersect_shape(query)
	var splash_dmg = _damage * splash_damage_ratio
	for result in results:
		var collider = result.get("collider")
		if not collider or not is_instance_valid(collider):
			continue
		var enemy = collider.owner if collider.owner else collider.get_parent()
		if enemy == hit_enemy or not enemy.has_method("take_damage"):
			continue
		enemy.take_damage(splash_dmg, false)
		if is_instance_valid(source_tower) and source_tower.has_method("report_damage"):
			source_tower.report_damage(splash_dmg)

func _release():
	if _trail:
		_trail.emitting = false
	super._release()
