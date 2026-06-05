# ===== 闪电链子弹（Mage 塔专用）=====
extends "res://子弹/bullet.gd"

var 发射点: Vector2 = Vector2.ZERO
var 跳跃衰减: float = 0.8
var 跳跃范围: float = 150.0
var 最大跳跃次数: int = 3

var 已命中列表: Array = []
var 闪电线条: Line2D = null
var _链启动: bool = false

func 初始化(起点: Vector2, 首个目标: Node2D, 伤害: float, 最大跳: int, 衰减: float, 范围: float, 来源塔 = null):
	发射点 = 起点
	target = 首个目标
	_damage = 伤害
	最大跳跃次数 = 最大跳
	跳跃衰减 = 衰减
	跳跃范围 = 范围
	已命中列表.clear()
	_has_hit = false
	_链启动 = false
	source_tower = 来源塔
	if 来源塔 and "tower_type" in 来源塔:
		var tt = 来源塔.tower_type
		_crit_chance = tt.crit_chance
		_crit_multiplier = tt.crit_multiplier
		_hit_chance = tt.hit_chance
		_attack_type = tt.attack_type

func _physics_process(_delta: float) -> void:
	if _链启动:
		return
	_链启动 = true
	set_physics_process(false)

	# 1. 收集路径点并造成伤害
	var 路径点: Array = [发射点]
	_do_chain(target, 最大跳跃次数, 路径点)

	# 2. 画完整闪电线
	_draw_lightning(路径点)

	# 3. 停留一会让玩家看到
	await get_tree().create_timer(0.25).timeout
	_release()

func _do_chain(enemy: Node2D, 剩余跳: int, 路径点: Array) -> void:
	if not is_instance_valid(enemy) or 剩余跳 <= 0:
		return
	已命中列表.append(enemy)
	_apply_damage(enemy)
	路径点.append(enemy.global_position)
	if 剩余跳 <= 1:
		return
	var next = _find_next_target(enemy)
	if next == null:
		return
	_do_chain(next, 剩余跳 - 1, 路径点)

func _find_next_target(from_enemy: Node2D) -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemy")
	var pos = from_enemy.global_position
	var best = null
	var best_dist = 跳跃范围 + 1.0
	for e in enemies:
		if not is_instance_valid(e):
			continue
		if e in 已命中列表:
			continue
		var d = e.global_position.distance_to(pos)
		if d <= 跳跃范围 and d < best_dist:
			best_dist = d
			best = e
	return best

func _draw_lightning(路径点: Array) -> void:
	if 路径点.size() < 2:
		return
	if 闪电线条 == null:
		闪电线条 = Line2D.new()
		闪电线条.width = 3
		闪电线条.default_color = Color(0.3, 0.7, 1.0, 0.9)
		add_child(闪电线条)
	闪电线条.clear_points()
	for i in 路径点.size():
		var pt: Vector2 = 路径点[i]
		if i > 0 and i < 路径点.size() - 1:
			pt += Vector2(randf_range(-30, 30), randf_range(-30, 30))
		if i == 0:
			pt += Vector2(randf_range(-15, 15), randf_range(-15, 15))
		闪电线条.add_point(to_local(pt))

func _release() -> void:
	if 闪电线条:
		闪电线条.queue_free()
		闪电线条 = null
	已命中列表.clear()
	_链启动 = false
	super._release()

func _on_area_entered(_area: Area2D) -> void:
	pass

func _hit() -> void:
	pass
