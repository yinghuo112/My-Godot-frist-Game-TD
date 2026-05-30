class_name Enemy
extends PathFollow2D

# --- 信号 ---
signal died(enemy)
signal reached_end

# --- 导出属性 ---
@export var speed: float = 150.0
@export var max_hp: float = 10.0
@export var gold_reward: int = 10
@export var lane_width: float = 40.0
@export var lane_change_speed: float = 120.0

# --- 运行时状态 ---
var current_hp: float
var _last_pos: Vector2 = Vector2.ZERO

# --- 超车状态机 ---
var target_v_offset: float = 0.0
var is_overtaking: bool = false
var overtake_target: Node2D = null

# --- 节点缓存 ---
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = $ProgressBar
@onready var ray_cast: RayCast2D = $RayCast2D
 
# 初始化怪物：设置血量、播放行走动画
func _ready():
	current_hp = max_hp
	if sprite:
		sprite.play("walk")
	_update_health_bar()

# 每帧沿路径前进，检测前方障碍并执行超车逻辑
func _physics_process(delta: float) -> void:
	if not is_overtaking:
		if ray_cast.is_colliding():
			var collider = ray_cast.get_collider()
			if collider and collider.owner and collider.is_in_group("enemy"):
				var front_monster = collider.owner
				if "speed" in front_monster and speed > front_monster.speed:
					is_overtaking = true
					overtake_target = front_monster
					if front_monster.v_offset >= 0:
						target_v_offset = -lane_width
					else:
						target_v_offset = lane_width
				else:
					progress += front_monster.speed * delta
					v_offset = move_toward(v_offset, 0.0, lane_change_speed * delta)
					return
	else:
		if is_instance_valid(overtake_target):
			if progress > overtake_target.progress + 50.0:
				is_overtaking = false
				overtake_target = null
				target_v_offset = 0.0
		else:
			is_overtaking = false
			target_v_offset = 0.0

	v_offset = move_toward(v_offset, target_v_offset, lane_change_speed * delta)
	progress += speed * delta

	var dx := global_position.x - _last_pos.x
	if dx < 0:
		sprite.flip_h = true
	elif dx > 0:
		sprite.flip_h = false

	var move_dir = global_position - _last_pos
	if move_dir.length_squared() > 0:
		ray_cast.target_position = move_dir.normalized() * 50

	_last_pos = global_position

	if progress_ratio >= 1.0:
		reach_end()

# 承受伤害：减少血量，更新血条，血量归零时死亡
func take_damage(amount: float) -> void:
	current_hp = maxf(current_hp - amount, 0)
	_update_health_bar()
	if current_hp <= 0:
		die()

# 到达终点：发射信号并销毁
func reach_end():
	reached_end.emit()
	queue_free()

# 死亡：播放音效，发射信号，销毁
func die():
	AudioManager.play_die()
	died.emit(self)
	queue_free()

# 更新血量进度条的显示
func _update_health_bar():
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = current_hp
