extends Area2D

@export var speed: float = 600.0    # 子弹飞行速度
@export var damage: int = 10        # 子弹伤害值

var target: Node2D = null           # 追踪的目标怪物
var velocity: Vector2 = Vector2.ZERO  # 当前速度向量
var _has_hit: bool = false          # 防止重复命中

# 战斗属性（由 tower_base._shoot() 传入）
var _crit_chance: float = 0.0
var _crit_multiplier: float = 1.0
var _hit_chance: float = 1.0
var _attack_type: int = 0  # TowerType.AttackType.PHYSICAL

# 初始化子弹碰撞掩码和命中信号
func _ready():
	collision_mask |= 2
	area_entered.connect(_on_area_entered)

# 初始化：设置目标、伤害和战斗属性
func initialize(p_target: Node2D, p_damage: float,
		p_crit_chance: float = 0.0, p_crit_mult: float = 1.0,
		p_hit_chance: float = 1.0, p_attack_type: int = 0) -> void:
	target = p_target
	damage = p_damage
	_crit_chance = p_crit_chance
	_crit_multiplier = p_crit_mult
	_hit_chance = p_hit_chance
	_attack_type = p_attack_type
	if is_instance_valid(target):
		look_at(target.global_position)

# 每帧追踪目标飞行或惯性飞行，接近目标时命中
func _physics_process(delta: float) -> void:
	if is_instance_valid(target):
		var direction = (target.global_position - global_position).normalized()
		velocity = direction * speed
		look_at(target.global_position)
		if global_position.distance_to(target.global_position) < 12.0:
			_hit()
			return
	else:
		if velocity == Vector2.ZERO:
			velocity = Vector2.RIGHT.rotated(rotation) * speed
		if global_position.distance_to(Vector2.ZERO) > 3000:
			queue_free()
			return
	global_position += velocity * delta

# 完整伤害计算：命中 → 暴击 → 抗性
func _calculate_final_damage(target_node: Node2D) -> Array:
	var final_damage = float(damage)
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

# 命中目标：计算最终伤害并调用敌人的受伤函数
func _hit() -> void:
	if _has_hit:
		return
	_has_hit = true
	if is_instance_valid(target) and target.has_method("take_damage"):
		var result = _calculate_final_damage(target)
		var final_damage = result[0]
		if final_damage > 0:
			target.take_damage(final_damage, result[1])
	queue_free()

# Area2D 碰撞回调：直接与敌方 Area2D 接触时触发
func _on_area_entered(area: Area2D) -> void:
	if _has_hit:
		return
	if area.is_in_group("enemy"):
		var enemy = area.get_parent()
		if enemy.has_method("take_damage"):
			var result = _calculate_final_damage(enemy)
			var final_damage = result[0]
			if final_damage > 0:
				enemy.take_damage(final_damage, result[1])
		_has_hit = true
		queue_free()
