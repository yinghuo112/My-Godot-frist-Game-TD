extends "res://子弹/bullet.gd"

const CANNON_EXPLOSION = preload("res://子弹/cannon_explosion.tscn")

@export var splash_radius: float = 50.0
@export var splash_damage_ratio: float = 0.35

var _splash_shape: CircleShape2D

func _ready():
	super()
	_splash_shape = CircleShape2D.new()
	_splash_shape.radius = splash_radius

func _draw():
	draw_circle(Vector2.ZERO, 5, Color(0.3, 0.25, 0.2))
	draw_circle(Vector2.ZERO, 7, Color(0.5, 0.4, 0.3, 0.4))
	draw_circle(Vector2.ZERO, 3, Color(0.6, 0.55, 0.45))

func _hit():
	if _has_hit:
		return
	_has_hit = true
	_spawn_explosion()
	_apply_damage(target)
	_splash_damage()
	call_deferred("_release")

func _on_area_entered(area):
	if _has_hit:
		return
	if area.is_in_group("enemy"):
		_has_hit = true
		var enemy = area.get_parent()
		_spawn_explosion()
		_apply_damage(enemy)
		_splash_damage()
		call_deferred("_release")

func _spawn_explosion():
	var explosion = CANNON_EXPLOSION.instantiate()
	explosion.global_position = global_position
	get_parent().add_child(explosion)

func _splash_damage():
	var space = get_world_2d().direct_space_state
	if not space:
		return
	var query = PhysicsShapeQueryParameters2D.new()
	query.set_shape(_splash_shape)
	query.transform = Transform2D(0, global_position)
	query.collision_mask = 2
	var results = space.intersect_shape(query)
	var splash_dmg = _damage * splash_damage_ratio
	for result in results:
		var collider = result.get("collider")
		if not collider or not is_instance_valid(collider):
			continue
		var enemy = collider.owner if collider.owner else collider.get_parent()
		if enemy == target or not enemy.has_method("take_damage"):
			continue
		enemy.take_damage(splash_dmg, false)
