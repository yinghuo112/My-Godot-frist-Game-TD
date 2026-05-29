class_name Enemy
extends PathFollow2D

# --- 信号 ---
signal died(enemy)       # 怪物死亡时发射，传递自身引用
signal reached_end       # 怪物到达终点时发射

# --- 导出属性（可在检查器/子类中覆盖） ---
@export var speed: float = 150.0         # 沿路径前进速度
@export var max_hp: float = 10.0         # 最大生命值
@export var gold_reward: int = 10        # 击杀后奖励金币
@export var lane_width: float = 40.0     # 变道超车时的横向偏移宽度
@export var lane_change_speed: float = 120.0  # 横向变道速度

# --- 运行时状态 ---
var current_hp: float
var _last_pos: Vector2 = Vector2.ZERO    # 上一帧位置，用于计算移动方向

# --- 超车状态机 ---
var target_v_offset: float = 0.0         # 目标垂直偏移量（横向目标位置）
var is_overtaking: bool = false          # 是否正在超车
var overtake_target: Node2D = null       # 正在超越的前方怪物

# --- 节点缓存 ---
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = $ProgressBar
@onready var ray_cast: RayCast2D = $RayCast2D
 
func _ready():
	current_hp = max_hp
	if sprite:
		sprite.play("walk")
	_update_health_bar()

func _physics_process(delta: float) -> void:
	# 状态 1：正常跟随路径，检测前方是否有障碍
	if not is_overtaking:
		if ray_cast.is_colliding():
			var collider = ray_cast.get_collider()
			# 只对标记为 "enemy" 的 Area2D 做反应（忽略塔、子弹等）
			if collider and collider.owner and collider.is_in_group("enemy"):
				var front_monster = collider.owner
				# 如果自己比前车快 → 执行超车
				if "speed" in front_monster and speed > front_monster.speed:
					is_overtaking = true
					overtake_target = front_monster
					# 前车偏右则往左超，前车偏左则往右超
					if front_monster.v_offset >= 0:
						target_v_offset = -lane_width
					else:
						target_v_offset = lane_width
				else:
					# 自己不比前车快 → 跟车排队，并向主车道靠拢
					progress += front_monster.speed * delta
					v_offset = move_toward(v_offset, 0.0, lane_change_speed * delta)
					return
	# 状态 2：超车中，判断何时可以切回主车道
	else:
		if is_instance_valid(overtake_target):
			# 当自己的路程领先前车 50 像素以上 → 超车完成
			if progress > overtake_target.progress + 50.0:
				is_overtaking = false
				overtake_target = null
				target_v_offset = 0.0
		else:
			# 前车已死亡或被销毁 → 中断超车
			is_overtaking = false
			target_v_offset = 0.0

	# 丝滑变道：逼近目标横向偏移
	v_offset = move_toward(v_offset, target_v_offset, lane_change_speed * delta)
	# 全速前进
	progress += speed * delta

	# 根据横向移动方向翻转精灵
	var dx := global_position.x - _last_pos.x
	if dx < 0:
		sprite.flip_h = true
	elif dx > 0:
		sprite.flip_h = false

	# 更新射线方向跟随当前移动方向
	var move_dir = global_position - _last_pos
	if move_dir.length_squared() > 0:
		ray_cast.target_position = move_dir.normalized() * 50

	_last_pos = global_position

	# 到达路径终点
	if progress_ratio >= 1.0:
		reach_end()

# --- 受伤 / 死亡 / 终点 ---
func take_damage(amount: float) -> void:
	current_hp = maxf(current_hp - amount, 0)
	_update_health_bar()
	if current_hp <= 0:
		die()

func reach_end():
	reached_end.emit()
	queue_free()

func die():
	died.emit(self)
	queue_free()

func _update_health_bar():
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = current_hp
