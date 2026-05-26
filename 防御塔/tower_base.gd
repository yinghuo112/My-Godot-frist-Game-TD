extends Node2D
class_name TowerBase # 声明类名，方便子类继承和类型检查

# --- 属性参数（可由子类覆盖或在检查器中修改） ---
## 基础攻击力：每次命中怪物扣除的血量
@export var damage: float = 5.0       # 攻击伤害
## 攻击冷却时间（单位：秒）
@export var fire_rate: float = 1.0 
## 攻击射程半径（单位：像素）    
@export var range_radius: float = 120.0 
## 建造花费
@export var cost: int = 50     

## 🌟 新增一个变量，用来控制当前要不要显示射程圈（默认不显示）
@export var show_range_circle: bool = false      

# --- 状态控制变量 ---
var can_shoot: bool = true            # 当前是否可以开火（冷却控制开关）
var target: Node2D = null              # 当前正在锁定的怪物目标（父节点 PathFollow2D）
var enemy_group: String = "enemy"      # 敌人的群组标签名称
var bullet_scene = preload("res://scenes/bullet.tscn")

# --- 节点引用（🌟 注意：这里修改为了 AnimatedSprite2D 以支持 8 帧动画） ---
@onready var sprite = get_node_or_null("AnimatedSprite2D")
@onready var range_area: Area2D = $RangeArea
@onready var range_shape: CollisionShape2D = $RangeArea/CollisionShape2D
@onready var shoot_timer: Timer = $ShootTimer
@onready var bullet_spawn: Marker2D = $BulletSpawn

# --- 初始化设置 ---
func _ready():
	# 修复：CollisionShape 位置归零，避免检测偏移
	range_shape.position = Vector2.ZERO
	# 动态将导出的 range_radius 变量赋值给碰撞圆形的半径，改变实际射程圈大小
	if range_shape and range_shape.shape is CircleShape2D:
		range_shape.shape.radius = range_radius
	
	# 设置计时器的等待时间为攻击冷却时间
	shoot_timer.wait_time = fire_rate
	
	# 连接计时器结束信号，用来刷新开火开关
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	
	# 连接检测区的进入和离开信号，用来感知怪物
	range_area.area_entered.connect(_on_enemy_entered)
	range_area.area_exited.connect(_on_enemy_exited)

	

# --- 每帧循环处理（核心控制流） ---
func _process(delta):
	# 判断当前有没有合法的目标
	if target and is_instance_valid(target):
		# 🌟【已取消】自动转头盯着怪物
		# sprite.look_at(target.global_position) 
		
		# 开火判定
		if can_shoot:
			_shoot()
			can_shoot = false
			shoot_timer.start()
	# 🌟 注意：这里去掉了你原有的 elif，保证没有怪时，冷却计时器也在后台默默跑完

# --- 射击与动画执行块（🌟 动画在这里重聚！） ---
func _shoot():
	# 1. 播放动画：命令你的 8 帧素材开始播放名为 "attack" 的开火动作
	if sprite and sprite.sprite_frames.has_animation("attack"):
		sprite.play("attack")
	
	# 2. 实例化子弹并传递数据
	var bullet = bullet_scene.instantiate()
	bullet.global_position = bullet_spawn.global_position
	bullet.initialize(target, damage)
	
	# 4. 生成子弹：把子弹作为主关卡 TowerDefense 的子节点注入到世界中
	var td_root = get_tree().root.get_node_or_null("TowerDefense")
	if td_root:
		td_root.add_child(bullet)
	else:
		get_parent().add_child(bullet) # 备用安全手段：找不到主场景就挂在防御塔同级

# --- 信号与逻辑处理块 ---

# 📡 当有物体的碰撞区进入射程
func _on_enemy_entered(area):
	# 确保进入的是带“enemy”标签的怪物碰撞体，且当前防御塔还没有锁定任何目标
	if area.is_in_group(enemy_group) and not target:
		# 拿到碰撞体的父节点（即真正沿着 Path 移动的怪物本体）
		target = area.get_parent()

# 📡 当怪物的碰撞区离开射程
func _on_enemy_exited(area):
	# 如果离开的这个怪刚好是当前锁定的目标
	if area.get_parent() == target:
		target = null           # 丢掉目标
		_find_next_target()     # 立刻在射程圈内搜寻下一个倒霉蛋

# 🎯 备用搜寻机制：在圈内的残留怪物中物色新目标
func _find_next_target():
	# 获取当前射程圈内所有重叠的 Area2D 数组
	var areas = range_area.get_overlapping_areas()
	for a in areas:
		# 挑出第一个带有 enemy 标签并且还活着的怪物
		if a.is_in_group(enemy_group) and is_instance_valid(a.get_parent()):
			target = a.get_parent() # 锁定它
			return                  # 找到一个就打住，退出函数
	target = null # 实在没有怪了，目标彻底清空

# 📡 计时器倒计时结束（冷却完毕）
func _on_shoot_timer_timeout():
	# 🌟 先判断：如果在此刻冷却完毕的一瞬间，依然没有找到任何目标
	if not target or not is_instance_valid(target):
		# 🌟 并且，如果我们的精灵节点（AnimatedSprite2D）存在
		if sprite:
			# 🌟 命令它停止当前正在播放的攻击动画，画面会静止在当前帧，或者返回到默认帧
			sprite.stop()
			# 或者命令它切换回一个“默认不动的帧”，如果你设置了的话：
			# sprite.animation = "idle" 
			# sprite.play()
			
	# 🌟 这一步不能忘！不管有没有目标，冷却完毕都标志着开火开关可以重新打开
	can_shoot = true
	
	
# 🌟 Godot 自带的 2D 绘图函数
func _draw():
	if show_range_circle:
		# 参数说明：draw_circle(中心点坐标, 半径, 颜色)
		# Color(红色, 绿色, 蓝色, 不透明度A) -> 这里配一个淡淡的半透明白色/蓝色
		draw_circle(Vector2.ZERO, range_radius, Color(1, 1, 1, 0.15))
		
		# 如果你还想要一圈细细的白色高亮外边框，可以再画一个空心圆：
		# draw_arc(Vector2.ZERO, range_radius, 0, TAU, 64, Color(1, 1, 1, 0.5), 1.0)
