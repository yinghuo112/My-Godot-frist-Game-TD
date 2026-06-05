# ===== 闪电链子弹（Mage 塔专用）=====
# 覆盖基类飞行逻辑：首帧收集目标并造成伤害，然后绘制闪电特效
# 特效：双 Line2D（主层+发光层）+ 多段锯齿抖动 + 火花粒子
extends "res://子弹/bullet.gd"

# ===== 链跳跃参数（由 mage_tower._shoot() 传入）=====
var 发射点: Vector2 = Vector2.ZERO          # 塔炮口世界坐标
var 跳跃衰减: float = 0.8                   # 每次跳跃伤害乘此系数
var 跳跃范围: float = 150.0                 # 搜索下一个目标的半径
var 最大跳跃次数: int = 3                    # 最多跳几次

# ===== 运行时状态 =====
var 已命中列表: Array = []                   # 已电过的敌人（避免重复跳跃）
var _链启动: bool = false                    # 防止 _physics_process 重入

# ===== 闪电视觉 =====
var 路径点: Array = []                       # 闪电经过的世界坐标点：炮口→敌1→敌2→...
var 主线条: Line2D = null                    # 主闪电线（细/亮/不透明）
var 发光线条: Line2D = null                  # 发光层（粗/半透明/Additive 混合）
var 抖动计时: float = 0.0                    # 累积时间，达 0.05s 触发重绘抖动
var 抖动总时长: float = 0.0                  # 从首次画线到现在，达 0.4s 释放


# ===== 初始化（由 mage_tower._shoot() 调用）=====
func 初始化(起点: Vector2, 首个目标: Node2D, 伤害: float,
            最大跳: int, 衰减: float, 范围: float, 来源塔 = null):
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


# ===== 第一帧执行链伤害 + 启动视觉 =====
func _physics_process(_delta: float) -> void:
	if _链启动:
		return
	_链启动 = true
	set_physics_process(false)

	路径点 = [发射点]
	_do_chain(target, 最大跳跃次数)
	_update_lines()
	for p in 路径点:
		if p != 发射点:
			_spawn_sparks(p)
	抖动计时 = 0.0
	抖动总时长 = 0.0
	set_process(true)


# ===== 抖动动画：每 0.05s 重新生成锯齿 =====
func _process(delta: float) -> void:
	抖动计时 += delta
	抖动总时长 += delta
	if 抖动计时 >= 0.05:
		抖动计时 = 0.0
		_update_lines()
	if 抖动总时长 >= 0.4:
		set_process(false)
		_release()


# ===== 递归链跳跃 + 伤害 =====
func _do_chain(enemy: Node2D, 剩余跳: int) -> void:
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
	_do_chain(next, 剩余跳 - 1)


# ===== 搜索跳跃范围内最近的未命中敌人 =====
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


# ===== 生成一段终点间的锯齿路径点 =====
# 起点→终点之间插入 段数-1 个抖动点，垂直方向随机偏移
# 偏移幅度按 sin(t*PI) 分布：中间最大、两端渐小
func _generate_segment(起点: Vector2, 终点: Vector2, 段数: int = 6) -> Array:
	var pts = []
	var dir = (终点 - 起点).normalized()
	var perp = Vector2(-dir.y, dir.x)
	var seg_len = 起点.distance_to(终点) / 段数
	pts.append(起点)
	for i in range(1, 段数):
		var t = float(i) / 段数
		var base = 起点.lerp(终点, t)
		var mag = seg_len * 0.35 * sin(t * PI)
		pts.append(base + perp * randf_range(-mag, mag))
	pts.append(终点)
	return pts


# ===== 绘制/更新双 Line2D =====
func _update_lines() -> void:
	if 路径点.size() < 2:
		return

	if not 主线条:
		主线条 = Line2D.new()
		主线条.width = 3
		主线条.default_color = Color(0.3, 0.8, 1.0, 0.95)
		add_child(主线条)

		发光线条 = Line2D.new()
		发光线条.width = 8
		发光线条.default_color = Color(0.2, 0.5, 1.0, 0.25)
		var mat = CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		发光线条.material = mat
		add_child(发光线条)

	var flat = []
	for i in range(路径点.size() - 1):
		var seg = _generate_segment(路径点[i], 路径点[i + 1], 6)
		if i > 0:
			seg.remove_at(0)
		flat += seg

	主线条.clear_points()
	发光线条.clear_points()
	for p in flat:
		var local_p = to_local(p)
		主线条.add_point(local_p)
		发光线条.add_point(local_p)


# ===== 在指定世界坐标生成火花粒子 =====
func _spawn_sparks(pos: Vector2) -> void:
	var p = GPUParticles2D.new()
	p.one_shot = true
	p.amount = 10
	p.lifetime = 0.3
	p.position = pos

	var mat = ParticleProcessMaterial.new()
	mat.direction = Vector3.UP
	mat.spread = 180
	mat.initial_velocity_min = 40
	mat.initial_velocity_max = 100
	mat.scale_amount_min = 1.0
	mat.scale_amount_max = 2.0
	p.process_material = mat

	get_parent().add_child(p)
	p.emitting = true
	await get_tree().create_timer(0.5).timeout
	if is_instance_valid(p):
		p.queue_free()


# ===== 清理：释放前删除视觉节点 =====
func _release() -> void:
	if 主线条:
		主线条.queue_free()
		主线条 = null
	if 发光线条:
		发光线条.queue_free()
		发光线条 = null
	已命中列表.clear()
	路径点.clear()
	_链启动 = false
	set_process(false)
	super._release()


# ===== 禁用基类碰撞命中（闪电链不走碰撞检测）=====
func _on_area_entered(_area: Area2D) -> void:
	pass

func _hit() -> void:
	pass
