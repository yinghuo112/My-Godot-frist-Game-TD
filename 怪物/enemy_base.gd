class_name Enemy
extends PathFollow2D

# --- 信号 ---
signal died(enemy)
signal reached_end

# --- 数据驱动（通过 EnemyType .tres 文件配置数值）---
var enemy_type            # 怪物类型数据（由生成器传入）

# 基础属性（init() 会从 EnemyType 覆盖这些值）
var speed: float = 150.0             # 移动速度
var max_hp: float = 10.0             # 最大生命
var gold_reward: int = 10            # 击杀奖励金币
var lane_width: float = 40.0         # 变道宽度
var lane_change_speed: float = 120.0 # 超车速度

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

var _floating_text_scene = preload("res://工具/FloatingText.tscn")
var _frame_skip: int = 0
var _main_scene: Node = null
var _original_modulate: Color

# --- 击退状态 ---
var _knockback_remaining: float = 0.0
var _knockback_speed: float = 250.0    # 击退速度（像素/秒）

# 由 GameManager 在生成时调用，传入 EnemyType 数据覆盖默认值
func init(data):
	enemy_type = data
	speed = data.speed
	max_hp = data.max_hp
	gold_reward = data.gold_reward
	lane_width = data.lane_width
	lane_change_speed = data.lane_change_speed
	current_hp = max_hp
 
# 初始化怪物：设置血量、播放行走动画
func _ready():
	current_hp = max_hp
	_main_scene = get_tree().current_scene
	_original_modulate = modulate
	if sprite:
		sprite.play("walk")
	_update_health_bar()

# 击退：沿路径向后推
func apply_knockback(force: float) -> void:
	_knockback_remaining += force
	modulate = Color(1.0, 0.5, 0.5)

# 每帧沿路径前进，检测前方障碍并执行超车逻辑
func _physics_process(delta: float) -> void:
	_frame_skip += 1
	var can_ray = _frame_skip >= 5
	if can_ray:
		_frame_skip = 0

	var did_block_move := false

	if not is_overtaking:
		if can_ray and ray_cast.is_colliding():
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
					did_block_move = true
	else:
		if is_instance_valid(overtake_target):
			if progress > overtake_target.progress + 50.0:
				is_overtaking = false
				overtake_target = null
				target_v_offset = 0.0
		else:
			is_overtaking = false
			target_v_offset = 0.0

	if not did_block_move:
		v_offset = move_toward(v_offset, target_v_offset, lane_change_speed * delta)
		progress += speed * delta

	if _knockback_remaining > 0:
		var step = minf(_knockback_remaining, _knockback_speed * delta)
		_knockback_remaining -= step
		progress -= step
		if _knockback_remaining <= 0:
			_knockback_remaining = 0.0
			modulate = _original_modulate

	var dx := global_position.x - _last_pos.x
	if dx < 0:
		sprite.flip_h = true
	elif dx > 0:
		sprite.flip_h = false

	var move_dir = global_position - _last_pos
	if can_ray and move_dir.length_squared() > 0:
		ray_cast.target_position = move_dir.normalized() * 50

	_last_pos = global_position

	if progress_ratio >= 1.0:
		reach_end()

# 承受伤害：减少血量，更新血条，血量归零时死亡
func take_damage(amount: float, is_crit: bool = false) -> void:
	current_hp = maxf(current_hp - amount, 0)
	_update_health_bar()

	_spawn_damage_text(amount, is_crit)

	if current_hp <= 0:
		die()

# 在怪物头顶生成伤害飘字
func _spawn_damage_text(amount: float, is_crit: bool) -> void:
	var main = _main_scene
	if not main:
		return

	var ft = _floating_text_scene.instantiate()
	ft.text = str(amount)

	if is_crit:
		ft.add_theme_color_override("font_color", Color(1, 0.2, 0.1))
	else:
		ft.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))

	ft.position = global_position - Vector2(100, 40)

	var dirs = [Vector2(0, -40), Vector2(-30, -40), Vector2(30, -40)]
	ft.float_direction = dirs[randi() % dirs.size()]

	main.add_child(ft)

# 获取闪避率（供子弹伤害计算调用）
func get_dodge_chance() -> float:
	return enemy_type.dodge_chance if enemy_type else 0.0

# 根据攻击类型获取对应抗性（供子弹伤害计算调用）
func get_armor(attack_type: int) -> float:
	if not enemy_type:
		return 0.0
	match attack_type:
		0: return enemy_type.armor_physical  # PHYSICAL
		1: return enemy_type.armor_magic     # MAGIC
		_: return 0.0

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
