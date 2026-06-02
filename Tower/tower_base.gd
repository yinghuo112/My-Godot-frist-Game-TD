extends Node2D
class_name TowerBase

# --- 数据驱动（通过 TowerType .tres 文件配置数值）---
var tower_type: TowerType            # 塔类型数据（由 main.gd 传入）

# 基础属性（init() 会从 TowerType 覆盖这些值）
var damage: float = 5.0              # 攻击力
var fire_rate: float = 1.0           # 射速（秒）
var range_radius: float = 120.0      # 射程
var cost: int = 50                   # 购买价格

@export var show_range_circle: bool = true  # 是否显示射程圈

# --- 升级系统 ---
var level: int = 1
var max_level: int = 3

var can_shoot: bool = true
var target: Node2D = null
var _tree_target: Node2D = null
var enemy_group: String = "enemy"
var bullet_scene = preload("res://核心/bullet.tscn")

@onready var sprite = get_node_or_null("AnimatedSprite2D")
@onready var range_area: Area2D = $RangeArea
@onready var range_shape: CollisionShape2D = $RangeArea/CollisionShape2D
@onready var shoot_timer: Timer = $ShootTimer
@onready var bullet_spawn: Marker2D = $BulletSpawn
@onready var level_label: Label = null

# 由 main.gd 在放置时调用，传入 TowerType 数据覆盖默认值
func init(data: TowerType):
	tower_type = data
	damage = data.damage
	fire_rate = data.fire_rate
	range_radius = data.range_radius
	cost = data.cost
	if data.bullet_scene:
		bullet_scene = data.bullet_scene

# 初始化范围碰撞体、射击计时器、范围检测和等级标签
func _ready():
	range_shape.position = Vector2.ZERO
	if range_shape and range_shape.shape is CircleShape2D:
		range_shape.shape.radius = range_radius

	shoot_timer.wait_time = fire_rate
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

# 每帧扫描目标并开火
func _process(delta):
	_find_next_target()
	if target and is_instance_valid(target):
		if can_shoot:
			_shoot()
			can_shoot = false
			shoot_timer.start()

# 播放攻击动画，生成子弹并发射
func _shoot():
	if sprite and sprite.sprite_frames.has_animation("attack"):
		sprite.play("attack")
	# 播放攻击音效
	AudioManager.play_shoot()
	var bullet = bullet_scene.instantiate()
	bullet.global_position = bullet_spawn.global_position
	bullet.initialize(target, get_current_damage(),
		tower_type.crit_chance, tower_type.crit_multiplier,
		tower_type.hit_chance, tower_type.attack_type)

	var td_root = get_tree().root.get_node_or_null("TowerDefense")
	if td_root:
		td_root.add_child(bullet)
	else:
		get_parent().add_child(bullet)

# 敌人或树进入范围时加入目标列表
func _on_area_entered(area):
	if area.is_in_group(enemy_group):
		var parent = area.get_parent()
		if parent is GameTree:
			_tree_target = parent
			if not target:
				target = _tree_target
		elif not target or (target and is_instance_valid(target) and target is GameTree):
			target = parent

# 敌人或树离开范围时重新选择目标
func _on_area_exited(area):
	var parent = area.get_parent()
	if parent == target:
		target = null
		if parent is GameTree:
			_tree_target = null
		_find_next_target()
	elif parent == _tree_target:
		_tree_target = null

# 在范围内寻找下一个最优目标（优先敌人，其次树）
func _find_next_target():
	var best_distance = INF
	var found_enemy = null
	var found_tree = null

	var areas = range_area.get_overlapping_areas()
	var range_sq = get_current_range() * get_current_range()
	for a in areas:
		if not a.is_in_group(enemy_group) or not is_instance_valid(a.get_parent()):
			continue
		var p = a.get_parent()
		if p is GameTree:
			if not found_tree:
				found_tree = p
		elif not found_enemy:
			found_enemy = p

	if not found_tree:
		for tree in get_tree().get_nodes_in_group("tree_group"):
			if not is_instance_valid(tree) or tree.state < tree.State.MATURE:
				continue
			var d2 = global_position.distance_squared_to(tree.global_position)
			if d2 < range_sq and d2 < best_distance:
				best_distance = d2
				found_tree = tree

	if found_enemy:
		target = found_enemy
	elif found_tree:
		target = found_tree
	_tree_target = found_tree if found_tree else null

# 射击冷却结束，标记可射击
func _on_shoot_timer_timeout():
	can_shoot = true

# 攻击动画播放完成后复位到第0帧
func _on_attack_anim_finished():
	sprite.frame = 0
	sprite.stop()

# 绘制范围指示圈
func _draw():
	if show_range_circle:
		draw_circle(Vector2.ZERO, get_current_range(), Color(1, 1, 1, 0.15))

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
	return total / 2

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
	if range_shape and range_shape.shape is CircleShape2D:
		range_shape.shape.radius = get_current_range()
	shoot_timer.wait_time = get_current_fire_rate()
	if level_label:
		level_label.text = "Lv." + str(level)
	queue_redraw()
	return true

# 计算当前等级伤害：基础值 × 1.5^(等级-1)
func get_current_damage() -> float:
	return damage * pow(1.5, level - 1)

# 计算当前等级射速：基础值 × 0.85^(等级-1)
func get_current_fire_rate() -> float:
	return fire_rate * pow(0.85, level - 1)

# 计算当前等级射程：基础值 × 4.0^(等级-1)
func get_current_range() -> float:
	return range_radius * pow(4.0, level - 1)
