extends Area2D

@export var speed: float = 600.0  # 箭矢飞行速度
@export var damage: int = 10      # 伤害值

var target: Node2D = null         # 锁定的敌人目标
var velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	# 初始时，如果目标存在，让子弹旋转并朝向目标
	if is_instance_valid(target):
		look_at(target.global_position)

func _physics_process(delta: float) -> void:
	# 强追踪逻辑：如果敌人还活着，不断更新方向
	if is_instance_valid(target):
		var direction = (target.global_position - global_position).normalized()
		velocity = direction * speed
		look_at(target.global_position) # 让箭尖始终指向敌人
	else:
		# 如果目标丢失（比如被其他塔杀了），子弹按最后的方向继续直线飞出屏幕
		if velocity == Vector2.ZERO:
			velocity = Vector2.RIGHT.rotated(rotation) * speed
	
	# 移动子弹
	global_position += velocity * delta

# 记得在节点面板（Node）中，将 Area2D 的 body_entered 信号连接到这里
func _on_body_entered(body: Node2D) -> void:
	# 假设你的怪物节点都分在了 "enemies" 组里
	if body.is_in_group("enemies"):
		if body.has_method("take_damage"):
			body.take_damage(damage) # 调用怪物的受伤函数
		queue_free() # 击中后销毁子弹
