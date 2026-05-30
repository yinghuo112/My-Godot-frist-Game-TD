extends Node2D
class_name GameTree

signal died(gold_reward)

enum State { SAPLING, MATURE }

@export var grow_time: float = 15.0
@export var max_hp: float = 30.0
@export var gold_reward: int = 15

var state: int = State.SAPLING
var current_hp: float
var is_marked: bool = false

@onready var visual: ColorRect = $Visual
@onready var area: Area2D = $Area2D
@onready var grow_timer: Timer = $GrowTimer

var floating_text_scene = preload("res://工具/FloatingText.tscn")
var countdown_label: Label = null

# 初始化树木：设置血量、视觉、生长计时器和碰撞检测
func _ready():
	add_to_group("tree_group")
	current_hp = max_hp
	_update_visual()
	grow_timer.wait_time = grow_time
	grow_timer.timeout.connect(_on_grow_timer_timeout)
	grow_timer.start()
	area.monitoring = false
	area.monitorable = false

	if state == State.SAPLING and floating_text_scene:
		countdown_label = floating_text_scene.instantiate()
		countdown_label.mode = countdown_label.Mode.COUNTDOWN
		var bottom_y = (visual.size.y / 2.0) + 5.0
		countdown_label.position = Vector2(-100, bottom_y)
		add_child(countdown_label)

# 每帧更新成长倒计时文字
func _process(_delta):
	if is_instance_valid(countdown_label) and not grow_timer.is_stopped():
		var time_left = ceil(grow_timer.time_left)
		countdown_label.text = str(time_left) + "s"

# 根据状态更新视觉大小和颜色
func _update_visual():
	match state:
		State.SAPLING:
			visual.color = Color(0.3, 0.8, 0.3)
			visual.size = Vector2(24, 24)
			visual.position = Vector2(-12, -12)
		State.MATURE:
			visual.color = Color(0.5, 0.3, 0.15)
			visual.size = Vector2(40, 40)
			visual.position = Vector2(-20, -20)

# 树木成熟：更新状态、开启碰撞检测、加入敌方组
func _on_grow_timer_timeout():
	state = State.MATURE
	_update_visual()
	grow_timer.stop()
	area.monitoring = true
	area.monitorable = true
	area.add_to_group("enemy")
	if is_instance_valid(countdown_label):
		countdown_label.queue_free()
		countdown_label = null

# 标记树木：仅改变视觉颜色
func mark():
	if state != State.MATURE or is_marked:
		return
	is_marked = true
	visual.modulate = Color(1, 0.7, 0.4)

# 取消标记：恢复视觉颜色
func unmark():
	if not is_marked:
		return
	is_marked = false
	visual.modulate = Color.WHITE

# 承受伤害：减少血量，更新视觉，血量为零时死亡
func take_damage(amount: float):
	current_hp = maxf(current_hp - amount, 0)
	var hp_ratio = current_hp / max_hp
	visual.color = Color(
		0.5 + 0.5 * hp_ratio,
		0.3 * hp_ratio,
		0.15 * hp_ratio
	)
	if current_hp <= 0:
		die()

# 树木死亡：发射信号并销毁
func die():
	died.emit(gold_reward)
	queue_free()
