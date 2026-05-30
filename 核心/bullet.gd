extends Area2D

@export var speed: float = 600.0    # 子弹飞行速度
@export var damage: int = 10        # 子弹伤害值

var target: Node2D = null           # 追踪的目标怪物
var velocity: Vector2 = Vector2.ZERO  # 当前速度向量

# 初始化子弹碰撞掩码和命中信号
func _ready():
	collision_mask |= 2
	area_entered.connect(_on_area_entered)

# 初始化：设置目标和伤害，并朝向目标
func initialize(p_target: Node2D, p_damage: float) -> void:
	target = p_target
	damage = p_damage
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

# 命中目标：调用敌人的受伤函数
func _hit() -> void:
	if is_instance_valid(target) and target.has_method("take_damage"):
		target.take_damage(damage)
	queue_free()

# Area2D 碰撞回调：直接与敌方 Area2D 接触时触发
func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy"):
		var enemy = area.get_parent()
		if enemy.has_method("take_damage"):
			enemy.take_damage(damage)
		queue_free()
