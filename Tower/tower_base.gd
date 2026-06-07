extends Node2D
class_name TowerBase

# --- 数据驱动（通过 TowerType .tres 文件配置数值）---
var tower_type: TowerType            # 塔类型数据（由 main.gd 传入）

# 基础属性（init() 会从 TowerType 覆盖这些值）
var damage: float = 5.0              # 攻击力
var fire_rate: float = 1.0           # 射速（秒）
var range_radius: float = 120.0      # 射程
var cost: int = 50                   # 购买价格

@export var _show_range_circle: bool = true  # 是否显示射程圈

# --- 升级系统 ---
var level: int = 1
var max_level: int = 3

# --- 技能系统 ---
var skill_points: int = 0
var skill_unlocked_indices: Array = []
var skill_states: Dictionary = {}
var _last_skills: Array = []
var _tick_accum: float = 0.0

var can_shoot: bool = true
var target: Node2D = null
var _tree_target: Node2D = null
var enemy_group: String = "enemy"
var bullet_scene = preload("res://子弹/bullet.tscn")

var _range_indicator: TowerRangeIndicator

# ===== #1 / #3: signal-driven target + cached refs + cached stats =====
var _enemies_in_range: Array = []
var _tree_search_timer: float = 0.0
var _cached_damage: float
var _cached_range: float
var _cached_fire_rate: float

@onready var _bullet_manager = get_node("/root/BulletManager")
@onready var _tower_defense_root = get_tree().root.get_node("TowerDefense")
@onready var sprite = get_node_or_null("AnimatedSprite2D")
@onready var range_area: Area2D = $RangeArea
@onready var range_shape: CollisionShape2D = $RangeArea/CollisionShape2D
@onready var shoot_timer: Timer = $ShootTimer
@onready var bullet_spawn: Marker2D = $BulletSpawn
@onready var level_label: Label = null

func _refresh_cached_stats():
	_cached_damage = get_current_damage()
	_cached_range = get_current_range()
	_cached_fire_rate = get_current_fire_rate()

# 由 main.gd 在放置时调用，传入 TowerType 数据覆盖默认值
func init(data: TowerType):
	tower_type = data
	damage = data.damage
	fire_rate = data.fire_rate
	range_radius = data.range_radius
	cost = data.cost
	if data.bullet_scene:
		bullet_scene = data.bullet_scene
	var sb = data.get("skill_book")
	if sb and sb.skills.size() > 0:
		skill_unlocked_indices.append(0)
		var root_skill = sb.skills[0]
		skill_states[root_skill.resource_path] = {"level": 1, "proficiency": 0}
		_last_skills = _get_active_skills()

# 初始化范围碰撞体、射击计时器、范围检测和等级标签
func _ready():
	_refresh_cached_stats()
	range_shape.position = Vector2.ZERO
	if range_shape and range_shape.shape is CircleShape2D:
		range_shape.shape.radius = _cached_range

	shoot_timer.wait_time = _cached_fire_rate
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	range_area.area_entered.connect(_on_area_entered)
	range_area.area_exited.connect(_on_area_exited)
	range_area.collision_mask |= 2

	if sprite and sprite.sprite_frames.has_animation("attack"):
		sprite.sprite_frames.set_animation_loop("attack", false)
		sprite.animation_finished.connect(_on_attack_anim_finished)
		sprite.frame = 0
		sprite.stop()

	level_label = Label.new()
	level_label.name = "LevelLabel"
	level_label.text = "Lv." + str(level)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.add_theme_color_override("font_color", Color(1, 0.9, 0.2))
	level_label.add_theme_font_size_override("font_size", 10)
	level_label.position = Vector2(-10, -40)
	add_child(level_label)

	_range_indicator = TowerRangeIndicator.new()
	_range_indicator.set_range(get_current_range())
	_range_indicator.visible = _show_range_circle
	add_child(_range_indicator)

# 每帧射击逻辑 + 懒搜索树木目标 + 技能 tick
func _process(delta):
	if target and is_instance_valid(target):
		if can_shoot:
			_shoot()
			can_shoot = false
			shoot_timer.start()
	if target == null or not is_instance_valid(target):
		_tree_search_timer += delta
		if _tree_search_timer >= 0.5:
			_tree_search_timer = 0.0
			_find_tree_target()
	_tick_accum += delta
	if _tick_accum >= 0.5:
		var tick_delta = _tick_accum
		_tick_accum = 0.0
		for s in _last_skills:
			if s and s.has_method("on_tower_tick"):
				s.on_tower_tick(self, tick_delta, get_skill_level(s))

# 播放攻击动画，生成子弹并发射
func _shoot():
	if sprite and sprite.sprite_frames.has_animation("attack"):
		sprite.play("attack")
	AudioManager.play_shoot()
	var bullet = _bullet_manager.get_bullet(bullet_scene) if _bullet_manager else bullet_scene.instantiate()
	if not bullet:
		return
	bullet.global_position = bullet_spawn.global_position
	_last_skills = _get_active_skills()
	bullet.initialize(target, _cached_damage,
		tower_type.crit_chance, tower_type.crit_multiplier,
		tower_type.hit_chance, tower_type.attack_type, self,
		_last_skills)

	for s in _last_skills:
		if s and s.has_method("on_pre_shot"):
			s.on_pre_shot(self, bullet, target, get_skill_level(s))

	if _tower_defense_root:
		_tower_defense_root.add_child(bullet)
	else:
		get_parent().add_child(bullet)

# ------ 目标管理：信号驱动（优先敌人列表，其次树木）------

func _pick_target():
	_enemies_in_range = _enemies_in_range.filter(func(e): return is_instance_valid(e))
	if _enemies_in_range.size() > 0:
		target = _enemies_in_range[0]
	elif _tree_target and is_instance_valid(_tree_target):
		target = _tree_target
	else:
		target = null

func _find_tree_target():
	if _tree_target and is_instance_valid(_tree_target):
		return
	var best = null
	var best_d2 = INF
	var range_sq = _cached_range * _cached_range
	for t in get_tree().get_nodes_in_group("tree_group"):
		if not is_instance_valid(t) or t.state < t.State.MATURE:
			continue
		var d2 = global_position.distance_squared_to(t.global_position)
		if d2 < range_sq and d2 < best_d2:
			best_d2 = d2
			best = t
	if best:
		_tree_target = best
		_pick_target()

# 敌人或树进入范围时加入目标列表
func _on_area_entered(area):
	if area.is_in_group(enemy_group):
		var parent = area.get_parent()
		if parent is GameTree:
			_tree_target = parent
			if not target or not is_instance_valid(target):
				target = _tree_target
		elif parent not in _enemies_in_range:
			_enemies_in_range.append(parent)
			_pick_target()

# 敌人或树离开范围时重新选择目标
func _on_area_exited(area):
	var parent = area.get_parent()
	if parent == target:
		if parent is GameTree:
			_tree_target = null
		else:
			_enemies_in_range.erase(parent)
		_pick_target()
	elif parent == _tree_target:
		_tree_target = null
	elif parent in _enemies_in_range:
		_enemies_in_range.erase(parent)

# 射击冷却结束，标记可射击
func _on_shoot_timer_timeout():
	can_shoot = true

# 攻击动画播放完成后复位到第0帧
func _on_attack_anim_finished():
	sprite.frame = 0
	sprite.stop()

# --- 升级接口（供 TowerActionRing 调用）---
# 检查是否可以继续升级
func can_upgrade() -> bool:
	return level < max_level

# 获取当前等级升级所需金币
func get_upgrade_cost() -> int:
	match level:
		1: return 80
		2: return 150
		_: return -1

# 计算出售价格 = 总投入的 50%
func get_sell_value() -> int:
	var total = cost
	for lv in range(1, level):
		total += get_upgrade_cost_at(lv)
	return int(float(total) / 2)

# 获取指定等级的升级花费
func get_upgrade_cost_at(lv: int) -> int:
	match lv:
		1: return 80
		2: return 150
		_: return 0

# 执行升级：扣除金币，更新属性，刷新视觉
func do_upgrade() -> bool:
	if not can_upgrade():
		return false
	var c = get_upgrade_cost()
	if not GameManager.spend_gold(c):
		return false
	level += 1
	skill_points += 1
	AudioManager.play("upgrade")
	_refresh_cached_stats()
	if range_shape and range_shape.shape is CircleShape2D:
		range_shape.shape.radius = _cached_range
	shoot_timer.wait_time = _cached_fire_rate
	if level_label:
		level_label.text = "Lv." + str(level)
	if _range_indicator:
		_range_indicator.set_range(_cached_range)
	return true

func get_skill_level(skill) -> int:
	if not skill:
		return 0
	var path = skill.resource_path
	if path in skill_states:
		return skill_states[path].get("level", 0)
	return 0

func _get_active_skills() -> Array:
	var sb = tower_type.get("skill_book") if tower_type else null
	if not sb:
		return []
	var result = []
	for idx in skill_unlocked_indices:
		if idx < 0 or idx >= sb.skills.size():
			continue
		var skill = sb.skills[idx]
		if get_skill_level(skill) > 0:
			result.append(skill)
	return result

# 计算当前等级伤害：基础值 × 1.5^(等级-1)
func get_current_damage() -> float:
	return damage * pow(1.5, level - 1)

# 计算当前等级射速：基础值 × 0.85^(等级-1)
func get_current_fire_rate() -> float:
	return fire_rate * pow(0.85, level - 1)

# 计算当前等级射程：基础值 × 4.0^(等级-1)
func get_current_range() -> float:
	return range_radius * pow(4.0, level - 1)
