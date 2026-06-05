extends Area2D

signal used_up(bullet)    # 子弹用尽信号 → 通知 BulletPool 回收

@export var _speed: float = 600.0    # 子弹飞行速度
@export var _damage: float = 10        # 子弹伤害值

var target: Node2D = null           # 追踪的目标怪物
var velocity: Vector2 = Vector2.ZERO  # 当前速度向量
var _has_hit: bool = false          # 防止重复命中
var _pool_managed: bool = false     # 是否由对象池管理（true=信号回收，false=queue_free）
var source_tower: Node2D = null     # 来源塔（技能回调用）

var _floating_text_scene = preload("res://工具/FloatingText.tscn")  # 伤害/闪避飘字

var _main_scene: Node = null
@onready var _collision_shape: CollisionShape2D = $CollisionShape2D

# 战斗属性（由 tower_base._shoot() 传入）
var _crit_chance: float = 0.0
var _crit_multiplier: float = 1.0
var _hit_chance: float = 1.0
var _attack_type: int = 0  # TowerType.AttackType.PHYSICAL

# 初始化子弹碰撞掩码和命中信号
func _ready():
	_main_scene = get_tree().current_scene
	collision_mask |= 2
	area_entered.connect(_on_area_entered)

# 初始化：设置目标、伤害和战斗属性
func initialize(p_target: Node2D, p_damage: float,
		p_crit_chance: float = 0.0, p_crit_mult: float = 1.0,
		p_hit_chance: float = 1.0, p_attack_type: int = 0,
		p_source_tower: Node2D = null) -> void:
	target = p_target
	_damage = p_damage
	_crit_chance = p_crit_chance
	_crit_multiplier = p_crit_mult
	_hit_chance = p_hit_chance
	_attack_type = p_attack_type
	source_tower = p_source_tower
	if is_instance_valid(target):
		look_at(target.global_position)

# 每帧追踪目标飞行或惯性飞行，出界/目标死亡/接近目标时释放
func _physics_process(delta: float) -> void:
	if not GameManager.play_area.has_point(global_position):
		call_deferred("_release")
		return
	if is_instance_valid(target):
		var direction = (target.global_position - global_position).normalized()
		velocity = direction * _speed
		look_at(target.global_position)
		if global_position.distance_to(target.global_position) < 12.0:
			_hit()
			return
	else:
		call_deferred("_release")
		return
	global_position += velocity * delta

# 完整伤害计算：命中 → 暴击 → 抗性
func _calculate_final_damage(target_node: Node2D) -> Array:
	var final_damage = float(_damage)
	var is_crit = false

	# 1. 命中判定 - 只有 Enemy 有闪避
	var dodge = 0.0
	if target_node.has_method("get_dodge_chance"):
		dodge = target_node.get_dodge_chance()
	var effective_hit = clampf(_hit_chance - dodge, 0.0, 1.0)
	if randf() > effective_hit:
		return [0.0, false]  # MISS

	# 2. 暴击判定
	if randf() < _crit_chance:
		final_damage *= _crit_multiplier
		is_crit = true

	# 3. 抗性减伤 - 只有 Enemy 有抗性
	if target_node.has_method("get_armor"):
		var armor = target_node.get_armor(_attack_type)
		final_damage *= clampf(1.0 - armor, 0.0, 1.0)

	return [maxf(final_damage, 1.0), is_crit]

func _apply_damage(enemy: Node2D) -> void:
	if not enemy.has_method("take_damage"):
		return
	var result = _calculate_final_damage(enemy)
	var dmg = result[0]
	var crit = result[1]
	if dmg > 0:
		enemy.take_damage(dmg, crit)
	else:
		_spawn_miss_text(enemy)
	if not is_instance_valid(source_tower) or not source_tower.has_method("get_skill_level"):
		return
	var tt = source_tower.get("tower_type")
	if not tt:
		return
	var sb = tt.get("skill_book")
	if not sb:
		return
	var unlocked = source_tower.get("skill_unlocked_indices") if "skill_unlocked_indices" in source_tower else []
	for idx in unlocked:
		if idx < 0 or idx >= sb.skills.size():
			continue
		var skill = sb.skills[idx]
		var lv = source_tower.get_skill_level(skill)
		if lv > 0 and skill.has_method("on_hit"):
			skill.on_hit(source_tower, self, enemy, dmg, crit, lv)

# 在敌人头上显示 MISS 闪避飘字
func _spawn_miss_text(enemy: Node2D) -> void:
	var root = _main_scene
	if not root:
		return
	var ft = _floating_text_scene.instantiate()
	ft.text = "MISS"
	ft.add_theme_color_override("font_color", Color(1, 1, 0.3))
	ft.position = enemy.global_position - Vector2(100, 40)
	ft.float_direction = Vector2(0, -50)
	root.add_child(ft)

# 命中判定成功 → 设锁防止重复 → 应用伤害 → 帧末释放回池
func _hit() -> void:
	if _has_hit:
		return
	_has_hit = true
	_apply_damage(target)
	call_deferred("_release")

# 碰撞检测命中敌人 → 设锁防止重复 → 应用伤害 → 帧末释放回池
func _on_area_entered(area: Area2D) -> void:
	if _has_hit:
		return
	if area.is_in_group("enemy"):
		_has_hit = true
		_apply_damage(area.get_parent())
		call_deferred("_release")

# 集中清理：隐藏 → 停止逻辑/碰撞 → 若池管则发射 used_up 信号通知 BulletPool 回收
func _release() -> void:
	visible = false
	set_process(false)
	set_physics_process(false)
	set_deferred("monitoring", false)
	_collision_shape.set_deferred("disabled", true)
	if _pool_managed:
		used_up.emit(self)
	else:
		queue_free()

# 复用前的重置：清空命中锁 → 恢复可见/逻辑/碰撞
func reset() -> void:
	_has_hit = false
	visible = true
	set_process(true)
	set_physics_process(true)
	set_deferred("monitoring", true)
	_collision_shape.set_deferred("disabled", false)
