# ===== 闪电链子弹（Mage 塔专用）=====
# 覆盖基类的飞行逻辑，不做飞行：首帧即命中目标并跳跃连锁
# 跳跃参数由 mage_tower.gd 的 _shoot() 通过 初始化() 传入
extends "res://子弹/bullet.gd"

var 发射点: Vector2 = Vector2.ZERO
var 当前伤害: float = 0.0
var 剩余跳跃次数: int = 3
var 跳跃衰减: float = 0.8
var 跳跃范围: float = 150.0

var 已命中列表: Array = []       # 已电过的敌人引用，避免重复跳
var 闪电线条: Line2D = null
var _链启动: bool = false       # 防止多帧重入

func 初始化(起点: Vector2, 首个目标: Node2D, 伤害: float, 最大跳跃次数: int, 衰减: float, 范围: float):
	发射点 = 起点
	target = 首个目标
	_damage = 伤害
	剩余跳跃次数 = 最大跳跃次数
	跳跃衰减 = 衰减
	跳跃范围 = 范围
	已命中列表.clear()
	当前伤害 = 伤害
	_has_hit = false
	_链启动 = false
	set_deferred("monitoring", false)

func _physics_process(_delta: float) -> void:
	if _链启动:
		return
	_链启动 = true
	_do_chain(target)
	call_deferred("_release")

func _do_chain(enemy: Node2D) -> void:
	if not is_instance_valid(enemy) or 剩余跳跃次数 <= 0:
		return
	已命中列表.append(enemy)
	# 对当前目标造成伤害（复用基类暴击/命中/抗性计算）
	_apply_damage(enemy)
	剩余跳跃次数 -= 1
	if 剩余跳跃次数 <= 0:
		return
	var next = _find_next_target(enemy)
	if next == null:
		return
	_draw_line(enemy.global_position, next.global_position)
	_do_chain(next)

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

func _draw_line(from: Vector2, to: Vector2) -> void:
	if 闪电线条 == null:
		闪电线条 = Line2D.new()
		闪电线条.width = 3
		闪电线条.default_color = Color(0.3, 0.7, 1.0, 0.9)
		add_child(闪电线条)
	var mid = (from + to) / 2 + Vector2(randf_range(-25, 25), randf_range(-25, 25))
	闪电线条.clear_points()
	闪电线条.add_point(to_local(from))
	闪电线条.add_point(to_local(mid))
	闪电线条.add_point(to_local(to))

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
