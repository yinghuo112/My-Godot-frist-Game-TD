# ===== 闪电链子弹（Mage 塔专用）=====
# 3条细白线并行抖动 + Timer 驱动跳跃延迟（有传播感）
extends "res://子弹/bullet.gd"

const SPARK_SCENE = preload("res://子弹/lightning_sparkle.tscn")

# ===== 链跳跃参数（由 mage_tower._shoot() 传入）=====
var 发射点: Vector2 = Vector2.ZERO
var 跳跃衰减: float = 0.8
var 跳跃范围: float = 150.0
var 最大跳跃次数: int = 7

# ===== 运行时状态 =====
var 已命中列表: Array = []
var _链启动: bool = false
var _chain_done: bool = false
var 当前跳跃数: int = 0

# ===== 闪电视觉 =====
var 路径点: Array = []
var _lines: Array[Line2D] = []
var 抖动计时: float = 0.0
var 抖动总时长: float = 0.0
var _chain_timer: Timer

# ===== 一次性初始化（池创建时只跑一次）=====
func _ready():
	super()
	for i in range(3):
		var line = Line2D.new()
		line.width = 1
		line.default_color = Color.WHITE
		var mat = CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		line.material = mat
		add_child(line)
		_lines.append(line)
	_chain_timer = Timer.new()
	_chain_timer.one_shot = true
	_chain_timer.name = "ChainTimer"
	_chain_timer.timeout.connect(_on_chain_timer_timeout)
	add_child(_chain_timer)

# ===== 每次射击前的初始化 =====
func 初始化(起点: Vector2, 首个目标: Node2D, 伤害: float,
			最大跳: int, 衰减: float, 范围: float, 来源塔 = null, 缓存技能: Array = []):
	发射点 = 起点
	target = 首个目标
	_damage = 伤害
	最大跳跃次数 = 最大跳
	跳跃衰减 = 衰减
	跳跃范围 = 范围
	_cached_skills = 缓存技能
	已命中列表.clear()
	_has_hit = false
	_链启动 = false
	_chain_done = false
	当前跳跃数 = 0
	抖动计时 = 0.0
	抖动总时长 = 0.0
	路径点.clear()
	for line in _lines:
		line.clear_points()
		line.visible = true
	source_tower = 来源塔
	if 来源塔 and "tower_type" in 来源塔:
		var tt = 来源塔.tower_type
		_crit_chance = tt.crit_chance
		_crit_multiplier = tt.crit_multiplier
		_hit_chance = tt.hit_chance
		_attack_type = tt.attack_type
		var c = tt.get("lightning_color")
		if c:
			for line in _lines:
				line.default_color = c

# ===== 首帧启动链 =====
func _physics_process(_delta):
	if _链启动:
		return
	_链启动 = true
	set_physics_process(false)
	路径点 = [发射点]
	_chain_step(target)
	抖动计时 = 0.0
	抖动总时长 = 0.0
	set_process(true)

# ===== 抖动动画 + 链完成后释放 =====
func _process(delta):
	# 每帧跟随敌人当前位置，线条不悬空
	for i in range(已命中列表.size()):
		var idx = i + 1
		if idx < 路径点.size() and is_instance_valid(已命中列表[i]):
			路径点[idx] = 已命中列表[i].global_position
	抖动计时 += delta
	抖动总时长 += delta
	if 抖动计时 >= 0.05:
		抖动计时 = 0.0
		_update_lines()
	if _chain_done and 抖动总时长 >= 0.4:
		set_process(false)
		_release()

# ===== 单步跳：击中 + 画线 + 火花 + 启 Timer =====
func _chain_step(enemy: Node2D):
	if not is_instance_valid(enemy):
		_chain_done = true
		return
	已命中列表.append(enemy)
	_apply_damage(enemy)
	AudioManager.play_lightning()
	路径点.append(enemy.global_position)
	_update_lines()
	_spawn_sparks(enemy.global_position)
	当前跳跃数 += 1
	if 当前跳跃数 >= 最大跳跃次数:
		_chain_done = true
		return
	_chain_timer.start(0.05)

# ===== Timer 回调 → 找下一目标继续跳 =====
func _on_chain_timer_timeout():
	var last = 已命中列表[-1] if 已命中列表.size() > 0 else null
	if not is_instance_valid(last):
		_chain_done = true
		return
	var next = _find_next_target(last)
	if next == null:
		_chain_done = true
		return
	_chain_step(next)

# ===== 搜索跳跃范围内最近的未命中敌人 =====
func _find_next_target(from_enemy: Node2D) -> Node2D:
	var nodes = get_tree().get_nodes_in_group("enemy")
	var pos = from_enemy.global_position
	var best = null
	var best_dist2 = (跳跃范围 + 1.0) * (跳跃范围 + 1.0)
	var range_sq = 跳跃范围 * 跳跃范围
	for n in nodes:
		if not is_instance_valid(n):
			continue
		var enemy = n.get_parent() if n is Area2D else n
		if not enemy.has_method("take_damage"):
			continue
		if enemy in 已命中列表:
			continue
		var d2 = enemy.global_position.distance_squared_to(pos)
		if d2 <= range_sq and d2 < best_dist2:
			best_dist2 = d2
			best = enemy
	return best

# ===== 3条线分别绘制，每条独立随机偏移 =====
func _update_lines():
	if 路径点.size() < 2:
		return
	for li in range(3):
		var pts: PackedVector2Array = []
		for i in range(路径点.size() - 1):
			var a = 路径点[i]
			var b = 路径点[i + 1]
			var seg = _jitter_segment(a, b, 6)
			if i > 0:
				seg.remove_at(0)
			for p in seg:
				pts.append(to_local(p))
		_lines[li].points = pts

# ===== 一段线段内的锯齿点（正弦幅度 + 全方向随机偏移）=====
func _jitter_segment(起点: Vector2, 终点: Vector2, 段数: int) -> Array:
	var pts = []
	var seg_len = 起点.distance_to(终点) / 段数
	pts.append(起点)
	for i in range(1, 段数):
		var t = float(i) / 段数
		var base = 起点.lerp(终点, t)
		var mag = seg_len * 0.35 * sin(t * PI)
		pts.append(base + Vector2(randf_range(-mag, mag), randf_range(-mag, mag)))
	pts.append(终点)
	return pts

# ===== 火花粒子 =====
func _spawn_sparks(pos: Vector2):
	var p = SPARK_SCENE.instantiate()
	p.global_position = pos
	get_parent().add_child(p)

# ===== 清理并回池 =====
func _release():
	_chain_done = false
	当前跳跃数 = 0
	if _chain_timer:
		_chain_timer.stop()
	已命中列表.clear()
	路径点.clear()
	for line in _lines:
		line.clear_points()
		line.visible = false
	_链启动 = false
	set_process(false)
	super._release()

# ===== 闪电链不走碰撞检测 =====
func _on_area_entered(_area):
	pass

func _hit():
	pass
