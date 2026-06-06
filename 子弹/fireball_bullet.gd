# ===== 火球子弹 =====
# 飞行追踪(带旋转) + 命中爆炸溅射范围伤害
extends "res://子弹/bullet.gd"

const _FIRE_EXPLOSION = preload("res://子弹/fireball_explosion.tscn")

@export var splash_radius: float = 60.0
@export var splash_damage_ratio: float = 0.5

@onready var bolt_sprite: Sprite2D = $Sprite2D
@onready var _trail: GPUParticles2D = $GPUParticles2D

var _anim_timer: float = 0.0
const ANIM_FPS: float = 6.0

func _ready():
	super()
	if bolt_sprite:
		bolt_sprite.hframes = 4
	if _trail:
		_trail.emitting = true

func _process(delta):
	_anim_timer += delta
	if _anim_timer >= 1.0 / ANIM_FPS:
		_anim_timer -= 1.0 / ANIM_FPS
		if bolt_sprite:
			bolt_sprite.frame = (bolt_sprite.frame + 1) % 4

func _hit():
	if _has_hit:
		return
	_has_hit = true
	_spawn_explosion()
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
	var circle = CircleShape2D.new()
	circle.radius = splash_radius
	query.set_shape(circle)
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

func _release():
	if _trail:
		_trail.emitting = false
	super._release()
